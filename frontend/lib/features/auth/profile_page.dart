import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_menu_tile.dart';
import 'package:kos_management/core/widgets/app_primary_button.dart';
import 'package:kos_management/core/widgets/app_text_field.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/notification/notification_settings_cards.dart';
import 'package:kos_management/features/subscription/subscription_cards.dart';
import 'package:kos_management/providers/profile_provider.dart';
import 'package:kos_management/service/api_service.dart';
import 'package:kos_management/service/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final AuthService _auth = AuthService(ApiService());
  bool _logoutLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().ambilProfile();
    });
  }

  Future<void> _logout(BuildContext context) async {
    if (_logoutLoading) return;
    setState(() => _logoutLoading = true);

    try {
      await _auth.logout();
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Logout server gagal, sesi lokal dihapus');
      }
    } finally {
      if (context.mounted) AppNavigation.goLogin(context);
    }
  }

  void _tampilkanPesan(ProfileProvider provider) {
    final sukses = provider.ambilPesanSukses();
    final error = provider.ambilPesanError();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (sukses != null) AppSnackbar.success(context, sukses);
      if (error != null) AppSnackbar.error(context, error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        _tampilkanPesan(provider);

        return Scaffold(
          backgroundColor: AppDesign.surface,
          appBar: AppBar(title: const Text('Profil Pemilik')),
          body: RefreshIndicator(
            onRefresh: () => provider.ambilProfile(force: true),
            child: _buildBody(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileProvider provider) {
    if (provider.loading && provider.profileData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.profileData == null) {
      return ListView(
        padding: const EdgeInsets.all(AppDesign.spaceLg),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.person_off_outlined, size: 56),
          const SizedBox(height: AppDesign.spaceMd),
          Text(
            'Profile belum bisa dimuat',
            textAlign: TextAlign.center,
            style: AppDesign.sectionTitle(context),
          ),
          const SizedBox(height: AppDesign.spaceMd),
          AppPrimaryButton(
            label: 'Muat ulang',
            icon: Icons.refresh_rounded,
            onPressed: () => provider.ambilProfile(force: true),
          ),
        ],
      );
    }

    final user = provider.user;
    final summary = provider.summary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.spaceMd,
        AppDesign.spaceMd,
        AppDesign.spaceMd,
        AppDesign.spaceXl,
      ),
      children: [
        _ProfileHeader(
          user: user,
          onPhotoTap: () => _showPhotoPreview(context, user),
        ),
        const SizedBox(height: AppDesign.spaceMd),
        _SectionLabel(
          title: 'Ringkasan',
          subtitle: 'Status data utama kos Anda',
        ),
        const SizedBox(height: AppDesign.spaceSm),
        _SummaryGrid(summary: summary),
        const SizedBox(height: AppDesign.spaceMd),
        const _SectionLabel(
          title: 'Akun',
          subtitle: 'Kelola identitas dan akses akun',
        ),
        const SizedBox(height: AppDesign.spaceSm),
        AppMenuTile(
          title: 'Edit Profil',
          subtitle: 'Ubah nama dan foto profil',
          icon: Icons.edit_outlined,
          onTap: () => _showEditProfileDialog(context, provider),
        ),
        if (provider.bisaGantiPassword)
          AppMenuTile(
            title: 'Ganti Password',
            subtitle: 'Perbarui password akun email',
            icon: Icons.lock_reset_rounded,
            onTap: () => _showPasswordDialog(context, provider),
          ),
        const SizedBox(height: AppDesign.spaceMd),
        const SubscriptionCards(),
        const SizedBox(height: AppDesign.spaceSm),
        const NotificationSettingsCards(),
        const SizedBox(height: AppDesign.spaceSm),
        const _SectionLabel(
          title: 'Lainnya',
          subtitle: 'Informasi aplikasi dan sesi login',
        ),
        const SizedBox(height: AppDesign.spaceSm),
        AppMenuTile(
          title: 'Tentang Aplikasi',
          subtitle: 'Kos Management MVP',
          icon: Icons.info_outline_rounded,
          onTap: () => _showAboutDialog(context),
        ),
        AppMenuTile(
          title: 'Logout',
          subtitle: _logoutLoading
              ? 'Sedang keluar...'
              : 'Keluar dari akun ini',
          icon: Icons.logout_rounded,
          iconColor: AppDesign.danger,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    ProfileProvider provider,
  ) async {
    final nama = TextEditingController(text: '${provider.user['nama'] ?? ''}');
    final fotoAwal = '${provider.user['foto_url'] ?? ''}'.trim();
    final pageNavigator = Navigator.of(context);
    final pageScaffoldMessenger = ScaffoldMessenger.of(context);
    XFile? fotoBaru;
    var dialogSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return _ProfileFormDialog(
              title: 'Edit Profil',
              subtitle: 'Perbarui nama dan foto yang tampil di aplikasi.',
              saving: dialogSaving,
              saveLabel: 'Simpan Profil',
              onCancel: () => Navigator.pop(dialogContext),
              onSave: () async {
                setDialogState(() => dialogSaving = true);
                final ok = await provider.updateProfile(
                  nama: nama.text.trim(),
                  fotoPath: fotoBaru?.path,
                  tampilkanPesanSukses: false,
                );
                if (!mounted) return;
                if (ok) {
                  if (pageNavigator.canPop()) {
                    pageNavigator.pop();
                  }
                  pageScaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (dialogContext.mounted) {
                  setDialogState(() => dialogSaving = false);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: _EditableAvatar(
                      fotoAwal: fotoAwal,
                      fotoBaru: fotoBaru,
                      onPick: dialogSaving
                          ? null
                          : () async {
                              final picked = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (!dialogContext.mounted) return;
                              if (picked == null) return;
                              setDialogState(() => fotoBaru = picked);
                            },
                    ),
                  ),
                  const SizedBox(height: AppDesign.spaceLg),
                  AppTextField(
                    label: 'Nama Pemilik',
                    hint: 'Nama lengkap pemilik',
                    controller: nama,
                    icon: Icons.person_outline_rounded,
                    required: true,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nama.dispose();
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    ProfileProvider provider,
  ) async {
    final lama = TextEditingController();
    final baru = TextEditingController();
    var dialogSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return _ProfileFormDialog(
              title: 'Ganti Password',
              subtitle: 'Perbarui password untuk akun email pemilik.',
              saving: dialogSaving,
              saveLabel: 'Ganti Password',
              onCancel: () => Navigator.pop(dialogContext),
              onSave: () async {
                setDialogState(() => dialogSaving = true);
                final ok = await provider.gantiPassword(
                  passwordLama: lama.text,
                  passwordBaru: baru.text,
                );
                if (!dialogContext.mounted) return;
                if (ok) {
                  Navigator.pop(dialogContext);
                  return;
                }
                setDialogState(() => dialogSaving = false);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Password Lama',
                    controller: lama,
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    required: true,
                  ),
                  AppTextField(
                    label: 'Password Baru',
                    controller: baru,
                    icon: Icons.lock_reset_rounded,
                    obscure: true,
                    required: true,
                    helperText: 'Minimal 6 karakter.',
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    lama.dispose();
    baru.dispose();
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Kos Management',
      applicationVersion: '1.0.0',
      children: const [Text('Aplikasi manajemen kos untuk pemilik kos.')],
    );
  }

  void _showPhotoPreview(BuildContext context, Map<String, dynamic> user) {
    final fotoUrl = '${user['foto_url'] ?? ''}'.trim();
    final nama = '${user['nama'] ?? 'Pemilik'}';
    if (fotoUrl.isEmpty) {
      AppSnackbar.error(context, 'Foto profil belum tersedia');
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppDesign.spaceMd),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.78,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppDesign.textPrimary,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                ),
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    fotoUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        'Foto tidak bisa dimuat',
                        style: AppDesign.bodyMuted(
                          dialogContext,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppDesign.spaceSm,
                right: AppDesign.spaceSm,
                child: IconButton(
                  style: IconButton.styleFrom(backgroundColor: AppDesign.card),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Tutup',
                ),
              ),
              Positioned(
                left: AppDesign.spaceMd,
                right: 56,
                bottom: AppDesign.spaceMd,
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onPhotoTap;

  const _ProfileHeader({required this.user, required this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    final fotoUrl = '${user['foto_url'] ?? ''}'.trim();
    final role = '${user['role'] ?? 'pemilik'}';
    final status = '${user['status'] ?? 'aktif'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: AppDesign.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onPhotoTap,
            borderRadius: BorderRadius.circular(999),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              backgroundImage: fotoUrl.isEmpty ? null : NetworkImage(fotoUrl),
              child: fotoUrl.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppDesign.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user['nama'] ?? 'Pemilik'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.sectionTitle(context),
                ),
                const SizedBox(height: AppDesign.spaceXs),
                Text(
                  '${user['email'] ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.bodyMuted(context),
                ),
                const SizedBox(height: AppDesign.spaceSm),
                Wrap(
                  spacing: AppDesign.spaceSm,
                  runSpacing: AppDesign.spaceSm,
                  children: [
                    _Badge(
                      label: role,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _Badge(
                      label: status,
                      color: status == 'aktif'
                          ? AppDesign.success
                          : AppDesign.warning,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFormDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool saving;
  final String saveLabel;
  final VoidCallback onCancel;
  final Future<void> Function() onSave;

  const _ProfileFormDialog({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.saving,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(AppDesign.spaceMd),
          decoration: AppDesign.cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppDesign.sectionTitle(context)),
                        const SizedBox(height: 4),
                        Text(subtitle, style: AppDesign.bodyMuted(context)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: saving ? null : onCancel,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spaceMd),
              const Divider(height: 1, color: AppDesign.border),
              const SizedBox(height: AppDesign.spaceMd),
              child,
              const SizedBox(height: AppDesign.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Batal',
                      outlined: true,
                      onPressed: saving ? null : onCancel,
                    ),
                  ),
                  const SizedBox(width: AppDesign.spaceSm),
                  Expanded(
                    child: AppPrimaryButton(
                      label: saveLabel,
                      icon: Icons.check_rounded,
                      loading: saving,
                      onPressed: saving ? null : () async => onSave(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  final String fotoAwal;
  final XFile? fotoBaru;
  final VoidCallback? onPick;

  const _EditableAvatar({
    required this.fotoAwal,
    required this.fotoBaru,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ImageProvider<Object>? image = fotoBaru != null
        ? FileImage(File(fotoBaru!.path))
        : fotoAwal.isEmpty
        ? null
        : NetworkImage(fotoAwal);

    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary.withValues(alpha: 0.1),
            border: Border.all(color: AppDesign.border),
          ),
          child: CircleAvatar(
            radius: 46,
            backgroundColor: Colors.transparent,
            backgroundImage: image,
            child: image == null
                ? Icon(Icons.person_rounded, size: 50, color: primary)
                : null,
          ),
        ),
        const SizedBox(height: AppDesign.spaceSm),
        SizedBox(
          height: 40,
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.photo_library_outlined, size: 18),
            label: Text(
              fotoBaru == null ? 'Pilih Foto' : 'Ganti Foto',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDesign.spaceSm,
      mainAxisSpacing: AppDesign.spaceSm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _SummaryTile(
          icon: Icons.apartment_rounded,
          label: 'Kos aktif',
          value: summary['total_kos'],
          color: Theme.of(context).colorScheme.primary,
        ),
        _SummaryTile(
          icon: Icons.meeting_room_rounded,
          label: 'Kamar aktif',
          value: summary['total_kamar'],
          color: AppDesign.info,
        ),
        _SummaryTile(
          icon: Icons.group_rounded,
          label: 'Penyewa aktif',
          value: summary['total_penyewa'],
          color: AppDesign.success,
        ),
        _SummaryTile(
          icon: Icons.receipt_long_rounded,
          label: 'Tagihan belum lunas',
          value: summary['tagihan_belum_lunas'],
          color: AppDesign.warning,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const Spacer(),
          Text(
            '${int.tryParse('$value') ?? 0}',
            style: AppDesign.sectionTitle(context).copyWith(fontSize: 22),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;

  const _Badge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionLabel({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppDesign.titleBold(context)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
