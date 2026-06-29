import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_chip.dart';
import 'package:kos_management/core/widgets/app_entity_action_controls.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/core/widgets/app_info_row.dart';
import 'package:kos_management/core/widgets/app_stat_card_compact.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/penyewa_detail/widget/card_rangkuman.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/penyewa_detail/widget/kontrak_detail_section.dart';
import 'package:kos_management/features/penyewa_detail/widget/tagihan_list_section.dart';
import 'package:kos_management/features/whatsapp/whatsapp_deep_link_service.dart';
import 'package:kos_management/features/whatsapp/whatsapp_settings_cards.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kontrak_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/providers/tagihan_provider.dart';
import 'package:kos_management/utils/sisa_hari.dart';
import 'package:kos_management/utils/tagihan_rules.dart';
import 'package:provider/provider.dart';

class PenyewaDetailPage extends StatefulWidget {
  final int id_penyewa;
  final int? id_kamar;
  final int? id_kos;

  const PenyewaDetailPage({
    super.key,
    required this.id_penyewa,
    this.id_kamar,
    this.id_kos,
  });

  @override
  State<PenyewaDetailPage> createState() => _PenyewaDetailPageState();
}

class _PenyewaDetailPageState extends State<PenyewaDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PenyewaProvider _penyewaRead;
  late KamarProvider _kamarRead;
  late TagihanProvider _tagihanRead;
  late KontrakProvider _kontrakRead;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _penyewaRead = context.read<PenyewaProvider>();
    _kamarRead = context.read<KamarProvider>();
    _tagihanRead = context.read<TagihanProvider>();
    _kontrakRead = context.read<KontrakProvider>();
    _penyewaRead.addListener(_listenerPenyewa);
    _kamarRead.addListener(_listenerKamar);
    _tagihanRead.addListener(_listenerTagihan);
    _kontrakRead.addListener(_listenerKontrak);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kamarId = widget.id_kamar;
      final kosId = widget.id_kos;
      if (kamarId != null) {
        _penyewaRead.ambil_data_penyewa_provider(kamarId);
      }
      if (kosId != null) {
        _kamarRead.ambil_data_kamar_provider(kosId);
      }
      // Penyewa nonaktif/tanpa kamar diambil dari master list.
      if (kamarId == null) {
        _penyewaRead.ambil_semua_penyewa();
      }
      _tagihanRead.ambil_data_tagihan_provider(widget.id_penyewa);
      _kontrakRead.ambil_kontrak_provider(widget.id_penyewa, force: true);
      context.read<KosProvider>().ambil_data_kos_provider();
    });
  }

  void _listenerPenyewa() => _showSnack(
    _penyewaRead.ambil_pesan_error(),
    _penyewaRead.ambil_pesan_sukses(),
  );
  void _listenerKamar() => _showSnack(
    _kamarRead.ambil_pesan_error(),
    _kamarRead.ambil_pesan_sukses(),
  );
  void _listenerTagihan() => _showSnack(
    _tagihanRead.ambil_pesan_error(),
    _tagihanRead.ambil_pesan_sukses(),
  );
  void _listenerKontrak() => _showSnack(
    _kontrakRead.ambil_pesan_error(),
    _kontrakRead.ambil_pesan_sukses(),
  );

  void _showSnack(String? err, String? ok) {
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

  Future<void> _chatWhatsApp(Map<String, dynamic> penyewa) async {
    final opened = await WhatsAppDeepLinkService.openChat(
      phoneNumber: penyewa['no_telpon']?.toString(),
      message:
          '${WhatsAppDeepLinkService.tenantGreeting(penyewa['nama']?.toString())}, saya menghubungi dari aplikasi Manajemen Kos.',
    );
    if (!mounted) return;
    if (!opened) {
      AppSnackbar.error(
        context,
        'Nomor WhatsApp belum valid atau WhatsApp tidak bisa dibuka.',
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _penyewaRead.removeListener(_listenerPenyewa);
    _kamarRead.removeListener(_listenerKamar);
    _tagihanRead.removeListener(_listenerTagihan);
    _kontrakRead.removeListener(_listenerKontrak);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final penyewaProv = context.watch<PenyewaProvider>();
    final penyewa =
        penyewaProv.penyewa_by_id[widget.id_penyewa] ??
        penyewaProv.semua_data_penyewa[widget.id_penyewa];
    final kamar = widget.id_kamar == null
        ? null
        : context.watch<KamarProvider>().kamar_by_id[widget.id_kamar];
    final kos = widget.id_kos == null
        ? null
        : context.watch<KosProvider>().dataKosMap[widget.id_kos];
    final tagihanList =
        context.watch<TagihanProvider>().data_tagihan[widget.id_penyewa] ?? [];

    if (penyewa == null || penyewa.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nama = '${penyewa['nama'] ?? ''}';
    final rangkuman = hitung_rangkuman(data: tagihanList);
    final kontrak = context
        .watch<KontrakProvider>()
        .kontrakByPenyewa[widget.id_penyewa];

    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: Column(
        children: [
          _buildTopBar(context, nama, kamar, kos, penyewa, kontrak),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppDesign.textSecondary,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Detail'),
                Tab(text: 'Kontrak'),
                Tab(text: 'Tagihan'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailTab(
                  context,
                  penyewa,
                  kamar,
                  kos,
                  tagihanList,
                  rangkuman,
                  kontrak,
                ),
                KontrakDetailSection(
                  idPenyewa: widget.id_penyewa,
                  idKamar: widget.id_kamar ?? 0,
                  idKos: widget.id_kos ?? 0,
                  embedded: true,
                ),
                Stack(
                  children: [
                    TagihanListSection(
                      idPenyewa: widget.id_penyewa,
                      idKamar: widget.id_kamar ?? 0,
                      idKos: widget.id_kos ?? 0,
                      embedded: true,
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Builder(
                        builder: (context) {
                          final blokir =
                              TagihanRules.pesanKontrakUntukBuatTagihan(
                                kontrak,
                              );
                          return Tooltip(
                            message: blokir ?? 'Buat tagihan baru',
                            child: AppAddFab(
                              tooltip: 'Tambah Tagihan',
                              onPressed: blokir == null
                                  ? () => AppNavigation.toTambahTagihan(
                                      context,
                                      idPenyewa: widget.id_penyewa,
                                      idKamar: widget.id_kamar ?? 0,
                                      idKos: widget.id_kos ?? 0,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
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

  Widget _buildTopBar(
    BuildContext context,
    String nama,
    Map<String, dynamic>? kamar,
    Map<String, dynamic>? kos,
    Map<String, dynamic> penyewa,
    Map<String, dynamic>? kontrak,
  ) {
    final bolehEdit = EntityActionRules.bolehEditPenyewa(penyewa);
    final subtitle = kamar != null && kos != null
        ? 'Kamar ${kamar['nomor']} · ${kos['nama_kos']}'
        : 'Pemenyewa Tidak tinggal';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            AppBackButton(onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => AppNavigation.toPenyewaProfile(
                      context,
                      idPenyewa: widget.id_penyewa,
                      idKamar: widget.id_kamar,
                      idKos: widget.id_kos,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Text(
                      nama,
                      style: AppDesign.titleBold(context).copyWith(
                        fontSize: 18,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            AppEntityIconAction(
              icon: Icons.edit_rounded,
              enabled: bolehEdit,
              activeColor: AppDesign.info,
              blockedMessage: EntityActionRules.pesanEditPenyewa(penyewa),
              onPressed: () => AppNavigation.toEditPenyewa(
                context,
                idPenyewa: widget.id_penyewa,
                nama: '${penyewa['nama'] ?? ''}',
                noTelpon: '${penyewa['no_telpon'] ?? ''}',
                email: '${penyewa['email'] ?? ''}',
                tanggalLahir: penyewa['tanggal_lahir']?.toString(),
                jenisKelamin: penyewa['jenis_kelamin']?.toString(),
                statusHubungan: penyewa['status_hubungan']?.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTab(
    BuildContext context,
    Map<String, dynamic> penyewa,
    Map<String, dynamic>? kamar,
    Map<String, dynamic>? kos,
    List<Map<String, dynamic>> tagihanList,
    Map rangkuman,
    Map<String, dynamic>? kontrak,
  ) {
    final bolehHapus = EntityActionRules.bolehHapusPenyewa(
      penyewa,
      kontrak: kontrak,
    );
    final status = '${penyewa['status'] ?? penyewa['status_sewa'] ?? 'aktif'}';
    final totalTagihan = rangkuman['tagihan'] ?? 0;
    final totalBayar = rangkuman['bayar'] ?? 0;
    final totalSisa = rangkuman['sisa'] ?? 0;
    final tanggalLahir = _tanggalOnly('${penyewa['tanggal_lahir'] ?? ''}');
    final jenisKelamin = _labelEnum('${penyewa['jenis_kelamin'] ?? ''}');
    final statusHubungan = _labelEnum('${penyewa['status_hubungan'] ?? ''}');
    final sisaKontrak = SisaHari.labelKontrak(
      kontrak?['tanggal_mulai'],
      kontrak?['tanggal_selesai'],
      status: kontrak?['status'],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context, penyewa, status),
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 360 ? 1 : 3;
                final spacing = AppDesign.spaceSm * (columns - 1);
                final width = (constraints.maxWidth - spacing) / columns;
                return Wrap(
                  spacing: AppDesign.spaceSm,
                  runSpacing: AppDesign.spaceSm,
                  children: [
                    SizedBox(
                      width: width,
                      child: AppStatCardCompact(
                        label: 'Tagihan',
                        value: AppDesign.formatRupiah(totalTagihan),
                        icon: Icons.receipt_long_outlined,
                        iconColor: AppColors.icon_uang,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: AppStatCardCompact(
                        label: 'Dibayar',
                        value: AppDesign.formatRupiah(totalBayar),
                        icon: Icons.payments_outlined,
                        iconColor: AppDesign.success,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: AppStatCardCompact(
                        label: 'Sisa',
                        value: AppDesign.formatRupiah(totalSisa),
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: AppColors.icon_penyewa,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDesign.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Penghuni',
                    style: AppDesign.titleBold(context),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth < 360 ? 1 : 2;
                      final spacing = 16.0 * (columns - 1);
                      final width = (constraints.maxWidth - spacing) / columns;
                      final items = <Widget>[
                        AppInfoRow(
                          icon: Icons.person_outline,
                          label: 'Nama',
                          value: '${penyewa['nama'] ?? '-'}',
                        ),
                        AppInfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Telepon',
                          value: '${penyewa['no_telpon'] ?? '-'}',
                        ),
                        if (tanggalLahir.isNotEmpty)
                          AppInfoRow(
                            icon: Icons.cake_outlined,
                            label: 'Tanggal lahir',
                            value: tanggalLahir,
                          ),
                        if (jenisKelamin.isNotEmpty)
                          AppInfoRow(
                            icon: Icons.wc_outlined,
                            label: 'Jenis kelamin',
                            value: jenisKelamin,
                          ),
                        if (statusHubungan.isNotEmpty)
                          AppInfoRow(
                            icon: Icons.favorite_border,
                            label: 'Status hubungan',
                            value: statusHubungan,
                          ),
                        if (penyewa['email'] != null &&
                            '${penyewa['email']}'.isNotEmpty)
                          AppInfoRow(
                            icon: Icons.mail_outline,
                            label: 'Email',
                            value: '${penyewa['email']}',
                          ),
                        if (kamar != null)
                          AppInfoRow(
                            icon: Icons.meeting_room_outlined,
                            label: 'Kamar',
                            value: '${kamar['nomor']}',
                          ),
                        if (kos != null)
                          AppInfoRow(
                            icon: Icons.home_work_outlined,
                            label: 'Kos',
                            value: '${kos['nama_kos']}',
                          ),
                        AppInfoRow(
                          icon: Icons.circle_outlined,
                          label: 'Status',
                          value: status,
                        ),
                        if (sisaKontrak != null)
                          AppInfoRow(
                            icon: Icons.timer_outlined,
                            label: 'Durasi kontrak',
                            value: sisaKontrak,
                          ),
                      ];
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final item in items)
                            SizedBox(width: width, child: item),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (kamar != null)
                        AppChip(
                          icon: Icons.meeting_room_outlined,
                          label: 'Kamar ${kamar['nomor']}',
                        ),
                      if (kos != null)
                        AppChip(
                          icon: Icons.home_work_outlined,
                          label: '${kos['nama_kos']}',
                        ),
                      AppChip(
                        icon: Icons.receipt_long_outlined,
                        label: '${tagihanList.length} tagihan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 320;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: stacked
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _tabController.animateTo(1),
                              icon: const Icon(Icons.description_outlined),
                              label: const Text(
                                'Lihat Kontrak',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: stacked
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 2,
                            child: OutlinedButton.icon(
                              onPressed: () => _tabController.animateTo(2),
                              icon: const Icon(Icons.receipt_long_rounded),
                              label: const Text(
                                'Lihat Tagihan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _chatWhatsApp(penyewa),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AppEntityOutlinedAction(
                      label: 'Hapus Penyewa',
                      icon: Icons.delete_outline,
                      enabled: bolehHapus,
                      activeColor: AppDesign.danger,
                      blockedMessage: EntityActionRules.pesanHapusPenyewa(
                        penyewa,
                        kontrak: kontrak,
                      ),
                      onPressed: () => showConfirmDeleteDialog(
                        context: context,
                        nama: '${penyewa['nama'] ?? 'penyewa'}',
                        entityLabel: 'penyewa',
                        onConfirm: () async {
                          final penyewaProvider = context
                              .read<PenyewaProvider>();
                          final kosProvider = context.read<KosProvider>();
                          await penyewaProvider.hapus_penyewa_provider(
                            widget.id_penyewa,
                          );
                          if (context.mounted) {
                            await kosProvider.ambil_data_kos_provider();
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: WhatsAppNumberInfo(
              phoneNumber: '${penyewa['no_telpon'] ?? ''}',
              status: penyewa['whatsapp'] is Map
                  ? '${penyewa['whatsapp']['status'] ?? ''}'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(
    BuildContext context,
    Map<String, dynamic> penyewa,
    String status,
  ) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.icon_penyewa.withValues(alpha: 0.9),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 80,
              color: Color(0x40FFFFFF),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xAA000000), Colors.transparent],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => AppNavigation.toPenyewaProfile(
                            context,
                            idPenyewa: widget.id_penyewa,
                            idKamar: widget.id_kamar,
                            idKos: widget.id_kos,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Text(
                            '${penyewa['nama'] ?? ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${penyewa['no_telpon'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppStatusBadge(status: status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tanggalOnly(String value) {
    final text = value.trim();
    if (text.isEmpty || text == 'null') return '';
    return text.split('T').first;
  }

  String _labelEnum(String value) {
    final text = value.trim();
    if (text.isEmpty || text == 'null') return '';
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }
}
