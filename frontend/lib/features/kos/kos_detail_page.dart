import 'package:flutter/material.dart';
import 'package:kos_management/core/color_costum/color_costum.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_add_fab.dart';
import 'package:kos_management/core/widgets/app_chip.dart';
import 'package:kos_management/core/widgets/app_entity_action_controls.dart';
import 'package:kos_management/core/widgets/app_back_button.dart';
import 'package:kos_management/utils/entity_action_rules.dart';
import 'package:kos_management/core/widgets/app_stat_card_compact.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';
import 'package:kos_management/features/export_pdf/laporan_property_pdf.dart';
import 'package:kos_management/features/export_pdf/pdf_export_service.dart';
import 'package:kos_management/features/export_pdf/pdf_helpers.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/widgets/confirm_delete_dialog.dart';
import 'package:kos_management/features/kamar/widget/kamar_list_section.dart';
import 'package:kos_management/providers/kamar_provider.dart';
import 'package:kos_management/providers/kos_provider.dart';
import 'package:kos_management/providers/laporan_kos_provider.dart';
import 'package:kos_management/providers/penyewa_provider.dart';
import 'package:provider/provider.dart';

class KosDetailPage extends StatefulWidget {
  final int idKos;

  const KosDetailPage({super.key, required this.idKos});

  @override
  State<KosDetailPage> createState() => _KosDetailPageState();
}

class _KosDetailPageState extends State<KosDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late KosProvider _read;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _read = context.read<KosProvider>();
    _read.addListener(_listener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().ambil_data_kos_provider();
      context.read<KamarProvider>().ambil_data_kamar_provider(widget.idKos);
      context.read<PenyewaProvider>().ambil_data_penyewa_by_kos_provider(
        widget.idKos,
      );
    });
  }

  void _listener() {
    final err = _read.ambil_pesan_error();
    final ok = _read.ambil_pesan_sukses();
    if (err != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.error(context, err);
      });
    }
    if (ok != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppSnackbar.success(context, ok);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _read.removeListener(_listener);
    super.dispose();
  }

  Map<String, dynamic>? _kos(KosProvider p) =>
      p.ambil_datasiap_kos_by_id(widget.idKos);

  Map<String, int> _kamarStats(KamarProvider p) {
    final list = p.data_kamar[widget.idKos] ?? [];
    return {
      'total': list.length,
      'terisi': list.where((e) => e['status_kondisi'] != 'kosong').length,
    };
  }

  Future<void> _exportLaporanProperty(
    Map<String, dynamic> kos,
    Map<String, int> stats,
  ) async {
    try {
      final laporan = context.read<LaporanKosProvider>();
      await laporan.ambil_or_fecth(widget.idKos);
      final statistik = laporan.data_laporan_kos[widget.idKos] ?? [];
      await PdfExportService.sharePdf(
        fileName: PdfHelpers.fileName(
          'laporan_property',
          code: '${kos['nama_kos'] ?? widget.idKos}',
        ),
        build: () => LaporanPropertyPdf.build(
          kos: kos,
          statistik: statistik,
          totalKamar: stats['total'] ?? 0,
          kamarTerisi: stats['terisi'] ?? 0,
          kamarKosong: (stats['total'] ?? 0) - (stats['terisi'] ?? 0),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal export PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kosProvider = context.watch<KosProvider>();
    final kamarProvider = context.watch<KamarProvider>();
    final kos = _kos(kosProvider);
    final stats = _kamarStats(kamarProvider);

    if (kos == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppDesign.surface,
      body: Column(
        children: [
          _buildTopBar(context, kos, stats),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: AppDesign.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Detail'),
                Tab(text: 'Kamar'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailTab(
                  context,
                  kos,
                  stats,
                  _kosUntukRules(kos, stats),
                ),
                Stack(
                  children: [
                    KamarListSection(
                      idKos: widget.idKos,
                      namaKos: '${kos['nama_kos']}',
                      showHeader: false,
                      embedded: true,
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: AppAddFab(
                        tooltip: 'Tambah Kamar',
                        onPressed: () async {
                          final ok = await AppNavigation.toTambahKamar(
                            context,
                            idKos: widget.idKos,
                          );
                          if (ok == true && context.mounted) {
                            await context
                                .read<KosProvider>()
                                .ambil_data_kos_provider();
                          }
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

  Map<String, dynamic> _kosUntukRules(
    Map<String, dynamic> kos,
    Map<String, int> stats,
  ) {
    return {...kos, 'jumlah_kamar': kos['jumlah_kamar'] ?? stats['total'] ?? 0};
  }

  Widget _buildTopBar(
    BuildContext context,
    Map<String, dynamic> kos,
    Map<String, int> stats,
  ) {
    final data = _kosUntukRules(kos, stats);
    final bolehEdit = EntityActionRules.bolehEditKos(data);
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
                    '${kos['nama_kos']}',
                    style: AppDesign.titleBold(context).copyWith(fontSize: 18),
                  ),
                  Text(
                    '${kos['alamat']}',
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
              blockedMessage: EntityActionRules.pesanEditKos(data),
              onPressed: () => AppNavigation.toEditKos(
                context,
                idKos: widget.idKos,
                nama: '${kos['nama_kos']}',
                alamat: '${kos['alamat']}',
                deskripsi: '${kos['deskripsi'] ?? ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTab(
    BuildContext context,
    Map<String, dynamic> kos,
    Map<String, int> stats,
    Map<String, dynamic> kosRules,
  ) {
    final bolehHapus = EntityActionRules.bolehHapusKos(kosRules);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHero(context, kos),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: AppStatCardCompact(
                    label: 'Kamar',
                    value: '${stats['total']} Unit',
                    icon: Icons.meeting_room_outlined,
                    iconColor: AppColors.icon_kamar,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCardCompact(
                    label: 'Terisi',
                    value: '${stats['terisi']} Penyewa',
                    icon: Icons.group_rounded,
                    iconColor: AppDesign.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppStatCardCompact(
                    label: 'Status',
                    value: '${kos['status']}',
                    icon: Icons.verified_outlined,
                    iconColor: AppColors.icon_kos,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tentang Kos', style: AppDesign.titleBold(context)),
                const SizedBox(height: 8),
                Text(
                  '${kos['deskripsi'] ?? 'Belum ada deskripsi.'}',
                  style: AppDesign.bodyMuted(context),
                ),
                const SizedBox(height: 24),
                Text('Informasi', style: AppDesign.titleBold(context)),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    AppChip(
                      icon: Icons.location_on_outlined,
                      label: '${kos['alamat']}',
                    ),
                    AppChip(
                      icon: Icons.home_work_outlined,
                      label: 'Status ${kos['status']}',
                    ),
                    AppChip(
                      icon: Icons.door_front_door_outlined,
                      label: '${stats['total']} Kamar',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => AppNavigation.toKosStatistik(
                          context,
                          idKos: widget.idKos,
                        ),
                        icon: const Icon(Icons.bar_chart_rounded),
                        label: const Text('Statistik'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppEntityOutlinedAction(
                        label: 'Hapus',
                        icon: Icons.delete_outline,
                        enabled: bolehHapus,
                        activeColor: AppDesign.danger,
                        blockedMessage: EntityActionRules.pesanHapusKos(
                          kosRules,
                        ),
                        onPressed: () => showConfirmDeleteDialog(
                          context: context,
                          nama: '${kos['nama_kos']}',
                          entityLabel: 'kos',
                          onConfirm: () async {
                            await context
                                .read<KosProvider>()
                                .hapus_kos_provider(widget.idKos);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _exportLaporanProperty(kos, stats),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Bagikan Laporan Property PDF'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, Map<String, dynamic> kos) {
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
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                  Theme.of(context).colorScheme.primary,
                ],
              ),
            ),
            child: const Icon(
              Icons.home_work_rounded,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${kos['nama_kos']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${kos['alamat']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
