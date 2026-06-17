import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/core/widgets/app_info_row.dart';
import 'package:kos_management/core/widgets/app_kontrak_list_card.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/utils/json_parse.dart';
import 'package:kos_management/utils/kontrak_status.dart';
import 'package:kos_management/utils/sisa_hari.dart';
import 'package:provider/provider.dart';

class ProfilePenyewaPage extends StatefulWidget {
  final int idPenyewa;
  final int? idKamar;
  final int? idKos;

  const ProfilePenyewaPage({
    super.key,
    required this.idPenyewa,
    this.idKamar,
    this.idKos,
  });

  @override
  State<ProfilePenyewaPage> createState() => _ProfilePenyewaPageState();
}

class _ProfilePenyewaPageState extends State<ProfilePenyewaPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final PenyewaProvider _penyewaRead;
  late final KontrakProvider _kontrakRead;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _penyewaRead = context.read<PenyewaProvider>();
    _kontrakRead = context.read<KontrakProvider>();
    _penyewaRead.addListener(_listenerPenyewa);
    _kontrakRead.addListener(_listenerKontrak);
    WidgetsBinding.instance.addPostFrameCallback((_) => _muatAwal());
  }

  Future<void> _muatAwal() async {
    final kamarId = widget.idKamar;
    final kosId = widget.idKos;
    if (kosId != null) {
      await context.read<KosProvider>().ambil_or_update_data();
      if (!mounted) return;
      await context.read<KamarProvider>().ambil_data_kamar_provider(kosId);
    }
    if (kamarId != null) {
      await _penyewaRead.ambil_data_penyewa_provider(kamarId);
    }
    await _penyewaRead.ambil_semua_penyewa();
    await _kontrakRead.ambil_list_kontrak_penyewa(
      widget.idPenyewa,
      force: true,
    );
  }

  void _listenerPenyewa() {
    final err = _penyewaRead.ambil_pesan_error();
    final ok = _penyewaRead.ambil_pesan_sukses();
    _showSnack(err, ok);
  }

  void _listenerKontrak() {
    final err = _kontrakRead.ambil_pesan_error();
    final ok = _kontrakRead.ambil_pesan_sukses();
    _showSnack(err, ok);
  }

  void _showSnack(String? err, String? ok) {
    if (!mounted) return;
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.error(context, err);
      });
    }
    if (ok != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppSnackbar.success(context, ok);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _penyewaRead.removeListener(_listenerPenyewa);
    _kontrakRead.removeListener(_listenerKontrak);
    super.dispose();
  }

  Map<String, dynamic>? _penyewa(PenyewaProvider provider) =>
      provider.penyewa_by_id[widget.idPenyewa] ??
      provider.semua_data_penyewa[widget.idPenyewa];

  Map<String, dynamic>? _kontrakBerjalan(List<Map<String, dynamic>> list) {
    for (final kontrak in list) {
      if (KontrakStatus.isAktif(kontrak) || KontrakStatus.isPending(kontrak)) {
        return kontrak;
      }
    }
    return null;
  }

  String _tanggal(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return '-';
    return text.split('T').first;
  }

  String _labelEnum(dynamic value) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty || text == 'null') return '-';
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }

  String _labelKontrak(Map<String, dynamic>? kontrak) {
    if (kontrak == null) return '-';
    final kode = '${kontrak['kode_kontrak'] ?? ''}'.trim();
    if (kode.isNotEmpty) return kode;
    return '#${kontrak['id'] ?? '-'}';
  }

  int? _kosIdForKontrak(Map<String, dynamic> kontrak) {
    final kamar = kontrak['kamar'];
    final kamarId =
        entityId(kontrak['kamar_id']) ??
        (kamar is Map ? entityId(kamar['id']) : null);
    final kosId = kamar is Map ? entityId(kamar['kos_id']) : null;
    return kosId ??
        (kamarId == null
            ? null
            : context.read<KamarProvider>().cari_kos_id(kamarId));
  }

  void _editPenyewa(Map<String, dynamic> penyewa) {
    AppNavigation.toEditPenyewa(
      context,
      idPenyewa: widget.idPenyewa,
      nama: '${penyewa['nama'] ?? ''}',
      noTelpon: '${penyewa['no_telpon'] ?? ''}',
      email: '${penyewa['email'] ?? ''}',
      tanggalLahir: penyewa['tanggal_lahir']?.toString(),
      jenisKelamin: penyewa['jenis_kelamin']?.toString(),
      statusHubungan: penyewa['status_hubungan']?.toString(),
    );
  }

  void _hapusPenyewa(Map<String, dynamic> penyewa) {
    showConfirmDeleteDialog(
      context: context,
      nama: '${penyewa['nama'] ?? 'penyewa'}',
      entityLabel: 'penyewa',
      onConfirm: () async {
        final provider = context.read<PenyewaProvider>();
        await provider.hapus_penyewa_provider(widget.idPenyewa);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final penyewaProv = context.watch<PenyewaProvider>();
    final kontrakProv = context.watch<KontrakProvider>();
    final penyewa = _penyewa(penyewaProv);
    final kontrakList =
        kontrakProv.kontrakListByPenyewa[widget.idPenyewa] ?? [];
    final kontrakBerjalan = _kontrakBerjalan(kontrakList);

    if (penyewa == null) {
      return Scaffold(
        backgroundColor: AppDesign.surface,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AppBackButton(onPressed: () => Navigator.pop(context)),
                ),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(penyewa, kontrakBerjalan),
            Material(
              color: AppDesign.card,
              child: TabBar(
                controller: _tabs,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: AppDesign.textSecondary,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Identitas'),
                  Tab(text: 'Riwayat'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildIdentitas(penyewa, kontrakBerjalan),
                  _buildRiwayat(kontrakList, kontrakProv.loading),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> penyewa,
    Map<String, dynamic>? kontrakBerjalan,
  ) {
    final canEdit = EntityActionRules.bolehEditPenyewa(penyewa);
    final canDelete = EntityActionRules.bolehHapusPenyewa(
      penyewa,
      kontrak: kontrakBerjalan,
    );

    final kontrakLabel = _labelKontrak(kontrakBerjalan);
    final telpon = '${penyewa['no_telpon'] ?? ''}'.trim();
    final statusPenyewa = '${penyewa['status'] ?? 'aktif'}'
        .trim()
        .toLowerCase();
    final statusKontrak = KontrakStatus.normalize(kontrakBerjalan?['status']);
    final showKontrakStatus =
        kontrakBerjalan != null && statusKontrak != statusPenyewa;

    return Container(
      color: AppDesign.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: AppDesign.cardDecoration(),
        child: Column(
          children: [
            Row(
              children: [
                AppBackButton(onPressed: () => Navigator.pop(context)),
                const Spacer(),
                _HeaderAction(
                  icon: Icons.edit_rounded,
                  color: AppDesign.info,
                  enabled: canEdit,
                  tooltip:
                      EntityActionRules.pesanEditPenyewa(penyewa) ??
                      'Edit penyewa',
                  onTap: () => _editPenyewa(penyewa),
                ),
                const SizedBox(width: 6),
                _HeaderAction(
                  icon: Icons.delete_outline,
                  color: AppDesign.danger,
                  enabled: canDelete,
                  tooltip:
                      EntityActionRules.pesanHapusPenyewa(
                        penyewa,
                        kontrak: kontrakBerjalan,
                      ) ??
                      'Hapus penyewa',
                  onTap: () => _hapusPenyewa(penyewa),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.icon_penyewa.withValues(alpha: 0.16),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: AppColors.icon_penyewa,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${penyewa['nama'] ?? 'Penyewa'}',
              textAlign: TextAlign.center,
              style: AppDesign.titleBold(
                context,
              ).copyWith(fontSize: 20, height: 1.15),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (telpon.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                telpon,
                textAlign: TextAlign.center,
                style: AppDesign.bodyMuted(
                  context,
                ).copyWith(fontSize: 12.5, height: 1.2),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                AppStatusBadge(status: statusPenyewa),
                if (showKontrakStatus) AppStatusBadge(status: statusKontrak),
              ],
            ),
            if (kontrakLabel != '-') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border: Border.all(color: AppDesign.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: AppDesign.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kontrak berjalan: $kontrakLabel',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitas(
    Map<String, dynamic> penyewa,
    Map<String, dynamic>? kontrakBerjalan,
  ) {
    final kamar = widget.idKamar == null
        ? null
        : context.watch<KamarProvider>().kamar_by_id[widget.idKamar];
    final kos = widget.idKos == null
        ? null
        : context.watch<KosProvider>().dataKosMap[widget.idKos];
    final sisaKontrak = SisaHari.labelKontrak(
      kontrakBerjalan?['tanggal_mulai'],
      kontrakBerjalan?['tanggal_selesai'],
      status: kontrakBerjalan?['status'],
    );

    return RefreshIndicator(
      onRefresh: _muatAwal,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDesign.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identitas Penyewa',
                  style: AppDesign.sectionTitle(context),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.person_outline,
                  label: 'Nama',
                  value: '${penyewa['nama'] ?? '-'}',
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: '${penyewa['no_telpon'] ?? '-'}',
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: '${penyewa['email'] ?? '-'}',
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.cake_outlined,
                  label: 'Tanggal lahir',
                  value: _tanggal(penyewa['tanggal_lahir']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Jenis kelamin',
                  value: _labelEnum(penyewa['jenis_kelamin']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.favorite_border,
                  label: 'Status hubungan',
                  value: _labelEnum(penyewa['status_hubungan']),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.circle_outlined,
                  label: 'Status penyewa',
                  value: _labelEnum(penyewa['status']),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDesign.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konteks Hunian', style: AppDesign.sectionTitle(context)),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.meeting_room_outlined,
                  label: 'Kamar saat ini',
                  value: kamar == null ? '-' : 'Kamar ${kamar['nomor']}',
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.home_work_outlined,
                  label: 'Kos',
                  value: kos == null ? '-' : '${kos['nama_kos']}',
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.description_outlined,
                  label: 'Kontrak berjalan',
                  value: _labelKontrak(kontrakBerjalan),
                ),
                const SizedBox(height: 14),
                AppInfoRow(
                  icon: Icons.timer_outlined,
                  label: 'Durasi kontrak',
                  value: sisaKontrak ?? '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayat(List<Map<String, dynamic>> kontrakList, bool loading) {
    if (loading && kontrakList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (kontrakList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _muatAwal,
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            Icon(Icons.description_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada riwayat kontrak',
              textAlign: TextAlign.center,
              style: AppDesign.sectionTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Kontrak akan muncul setelah penyewa check-in atau dibuatkan kontrak.',
              textAlign: TextAlign.center,
              style: AppDesign.bodyMuted(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _muatAwal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        itemCount: kontrakList.length,
        itemBuilder: (context, index) {
          final kontrak = kontrakList[index];
          final kontrakId = entityId(kontrak['id']);
          final kamarId = entityId(kontrak['kamar_id']);
          if (kontrakId == null) return const SizedBox.shrink();
          return AppKontrakListCard(
            kontrak: kontrak,
            onTap: () => AppNavigation.toKontrakDetail(
              context,
              kontrakId: kontrakId,
              idPenyewa: widget.idPenyewa,
              idKamar: kamarId,
              idKos: _kosIdForKontrak(kontrak) ?? widget.idKos,
              kontrak: kontrak,
            ),
            onEdit: kamarId == null
                ? null
                : () async {
                    final ok = await AppNavigation.toEditKontrak(
                      context,
                      kontrakId: kontrakId,
                      idPenyewa: widget.idPenyewa,
                      idKamar: kamarId,
                      harga: '${kontrak['harga_sewa']}',
                      mulai: '${kontrak['tanggal_mulai']}'.split('T').first,
                      selesai: '${kontrak['tanggal_selesai']}'.split('T').first,
                      siklus: '${kontrak['siklus'] ?? 'bulanan'}',
                    );
                    if (!mounted || ok != true) return;
                    await _muatAwal();
                  },
            onDelete: () => showConfirmDeleteDialog(
              context: context,
              nama: '${kontrak['kode_kontrak'] ?? '#$kontrakId'}',
              entityLabel: 'kontrak',
              onConfirm: () async {
                await _kontrakRead.batalkan_kontrak_provider(
                  kontrakId: kontrakId,
                  penyewaId: widget.idPenyewa,
                );
                if (!mounted) return;
                await _muatAwal();
              },
            ),
          );
        },
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = enabled ? color : AppDesign.textTertiary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: activeColor.withValues(alpha: enabled ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: activeColor),
          ),
        ),
      ),
    );
  }
}
