import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_entity_action_controls.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/core/widgets/app_info_row.dart';
import 'package:kos_management/core/widgets/app_stat_card_compact.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/kamar/widget/kamar_fasilitas_chips.dart';
import 'package:kos_management/features/penyewa/widget/penyewa_list_section.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:kos_management/utils/kamar_fasilitas.dart';
import 'package:provider/provider.dart';

class KamarDetailPage extends StatefulWidget {
  final int idKamar;
  final int idKos;

  const KamarDetailPage({
    super.key,
    required this.idKamar,
    required this.idKos,
  });

  @override
  State<KamarDetailPage> createState() => _KamarDetailPageState();
}

class _KamarDetailPageState extends State<KamarDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late KamarProvider _kamarRead;
  late PenyewaProvider _penyewaRead;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _kamarRead = context.read<KamarProvider>();
    _penyewaRead = context.read<PenyewaProvider>();
    _kamarRead.addListener(_listenerKamar);
    _penyewaRead.addListener(_listenerPenyewa);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KamarProvider>().ambil_data_kamar_provider(widget.idKos);
      context.read<KosProvider>().ambil_data_kos_provider();
      context.read<PenyewaProvider>().ambil_data_penyewa_provider(
        widget.idKamar,
      );
    });
  }

  void _listenerKamar() {
    final err = _kamarRead.ambil_pesan_error();
    final ok = _kamarRead.ambil_pesan_sukses();
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

  void _listenerPenyewa() {
    final err = _penyewaRead.ambil_pesan_error();
    final ok = _penyewaRead.ambil_pesan_sukses();
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
    _tabController.dispose();
    _kamarRead.removeListener(_listenerKamar);
    _penyewaRead.removeListener(_listenerPenyewa);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kamar = context.watch<KamarProvider>().kamar_by_id[widget.idKamar];
    final kos = context.watch<KosProvider>().ambil_datasiap_kos_by_id(
      widget.idKos,
    );
    final penyewaList =
        context.watch<PenyewaProvider>().data_penyewa[widget.idKamar] ?? [];

    if (kamar == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: Column(
        children: [
          _buildTopBar(context, kamar, kos?['nama_kos']?.toString()),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppDesign.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Detail'),
                Tab(text: 'Penyewa'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailTab(context, kamar, penyewaList.length),
                Stack(
                  children: [
                    PenyewaListSection(
                      idKamar: widget.idKamar,
                      idKos: widget.idKos,
                      nomorKamar: '${kamar['nomor']}',
                      embedded: true,
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: AppAddFab(
                        tooltip: 'Tambah Penyewa',
                        onPressed: () => AppNavigation.toTambahPenyewaKontrak(
                          context,
                          idKamar: widget.idKamar,
                          idKos: widget.idKos,
                        ),
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
    Map<String, dynamic> kamar,
    String? namaKos,
  ) {
    final bolehEdit = EntityActionRules.bolehEditKamar(kamar);
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
                  Text(
                    'Kamar ${kamar['nomor']}',
                    style: AppDesign.titleBold(context).copyWith(fontSize: 18),
                  ),
                  Text(
                    namaKos != null ? '$namaKos' : 'Detail kamar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            AppEntityIconAction(
              icon: Icons.edit_rounded,
              enabled: bolehEdit,
              activeColor: AppDesign.info,
              blockedMessage: EntityActionRules.pesanEditKamar(kamar),
              onPressed: () => AppNavigation.toEditKamar(
                context,
                idKamar: widget.idKamar,
                idKos: widget.idKos,
                nomor: '${kamar['nomor']}',
                harga: '${kamar['harga']}',
                kapasitas: '${kamar['kapasitas']}',
                fasilitas: KamarFasilitas.parse(kamar['fasilitas']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTab(
    BuildContext context,
    Map<String, dynamic> kamar,
    int jumlahPenyewa,
  ) {
    final bolehHapus = EntityActionRules.bolehHapusKamar(kamar);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context, kamar),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: AppStatCardCompact(
                    label: 'Harga',
                    value: AppDesign.formatRupiah(kamar['harga']),
                    icon: Icons.payments_outlined,
                    iconColor: AppColors.icon_uang,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCardCompact(
                    label: 'Kapasitas',
                    value: '${kamar['kapasitas']} org',
                    icon: Icons.people_alt_outlined,
                    iconColor: AppDesign.info,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCardCompact(
                    label: 'Penyewa',
                    value: '$jumlahPenyewa',
                    icon: Icons.group_outlined,
                    iconColor: AppDesign.success,
                  ),
                ),
              ],
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
                    'Spesifikasi Kamar',
                    style: AppDesign.titleBold(context),
                  ),
                  const SizedBox(height: 16),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.4,
                        ),
                    children: [
                      AppInfoRow(
                        icon: Icons.door_front_door_outlined,
                        label: 'Nomor',
                        value: '${kamar['nomor']}',
                      ),
                      AppInfoRow(
                        icon: Icons.people_alt_outlined,
                        label: 'Kapasitas',
                        value: '${kamar['kapasitas']} orang',
                      ),
                      AppInfoRow(
                        icon: Icons.payments_outlined,
                        label: 'Harga',
                        value: AppDesign.formatRupiah(kamar['harga']),
                      ),
                      AppInfoRow(
                        icon: Icons.circle_outlined,
                        label: 'Status',
                        value: '${kamar['status_kondisi']}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Fasilitas', style: AppDesign.titleBold(context)),
                  const SizedBox(height: 10),
                  KamarFasilitasChips(
                    fasilitas: kamar['fasilitas'],
                    emptyLabel: 'Belum ada fasilitas tercatat',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _tabController.animateTo(1),
                          icon: const Icon(Icons.people_rounded),
                          label: const Text('Lihat Penyewa'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppEntityOutlinedAction(
                          label: 'Hapus',
                          icon: Icons.delete_outline,
                          enabled: bolehHapus,
                          activeColor: AppDesign.danger,
                          blockedMessage: EntityActionRules.pesanHapusKamar(
                            kamar,
                          ),
                          onPressed: () => showConfirmDeleteDialog(
                            context: context,
                            nama: '${kamar['nomor']}',
                            entityLabel: 'kamar',
                            onConfirm: () async {
                              final kamarProvider = context
                                  .read<KamarProvider>();
                              final kosProvider = context.read<KosProvider>();
                              await kamarProvider.hapus_kamar_provider(
                                widget.idKamar,
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
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Map<String, dynamic> kamar) {
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
                  AppColors.icon_kamar.withValues(alpha: 0.85),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
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
                        Text(
                          AppDesign.formatRupiah(kamar['harga']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'per bulan',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  AppStatusBadge(status: '${kamar['status_kondisi']}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
