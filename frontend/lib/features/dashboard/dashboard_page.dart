import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_hero_profile_button.dart';
import 'package:kos_management/core/widgets/app_page_scaffold.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_activity_list.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_category_header.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_featured_revenue.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_kpi_grid.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_occupancy_bars.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_occupancy_donut.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_quick_actions.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_tagihan_alert.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_tagihan_status.dart';
import 'package:kos_management/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _refreshTerjadwal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().muatRingkasan();
    });
  }

  void _muatJikaPerlu(DashboardProvider dashboard) {
    if (!dashboard.perluMuatUlang || dashboard.loading || _refreshTerjadwal) {
      return;
    }
    _refreshTerjadwal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<DashboardProvider>().muatRingkasan();
      } finally {
        _refreshTerjadwal = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    _muatJikaPerlu(dashboard);

    return AppPageScaffold(
      title: 'Halo, ${dashboard.namaPemilik}',
      subtitle: dashboard.loading && !dashboard.loaded
          ? 'Memuat ringkasan...'
          : 'Ringkasan ${dashboard.periodeLabel}',
      trailing: AppHeroProfileButton(nama: dashboard.namaPemilik),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<DashboardProvider>().muatRingkasan(force: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceMd,
            AppDesign.spaceMd,
            AppDesign.spaceMd,
            AppDesign.spaceXl,
          ),
          children: [
            if (dashboard.loading && !dashboard.loaded) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: AppDesign.spaceMd),
            ],
            if (dashboard.pesanError case final err?) ...[
              _DashboardError(message: err),
              const SizedBox(height: AppDesign.spaceMd),
            ],

            // Grafik utama
            DashboardFeaturedRevenue(
              periodeLabel: dashboard.periodeLabel,
              pendapatanBulanIni: dashboard.pendapatanBulanIni,
              pendapatanBulanLalu: dashboard.pendapatanBulanLalu,
              deltaPendapatanPersen: dashboard.deltaPendapatanPersen,
              trendPendapatan: dashboard.trendPendapatan,
              tampilkanTrend: dashboard.tampilkanTrendPendapatan,
            ),
            const SizedBox(height: AppDesign.spaceLg),

            const DashboardQuickActions(),
            const SizedBox(height: AppDesign.spaceLg),

            const DashboardCategoryHeader(
              icon: Icons.insights_rounded,
              title: 'Ringkasan',
              subtitle: 'Angka utama properti',
            ),
            DashboardKpiGrid(
              jumlahKos: dashboard.jumlahKos,
              okupansiPersen: dashboard.okupansiPersen,
              penyewaAktif: dashboard.penyewaAktif,
              kontrakAktif: dashboard.kontrakAktif,
            ),
            const SizedBox(height: AppDesign.spaceLg),

            if (dashboard.tampilkanHunianDetail) ...[
              const DashboardCategoryHeader(
                icon: Icons.meeting_room_rounded,
                title: 'Hunian',
                subtitle: 'Okupansi kamar',
              ),
              DashboardOccupancyDonut(
                totalKamar: dashboard.totalKamar,
                kamarTerisi: dashboard.kamarTerisi,
                okupansiPersen: dashboard.okupansiPersen,
              ),
              const SizedBox(height: AppDesign.spaceMd),
              DashboardOccupancyBars(
                totalKamar: dashboard.totalKamar,
                kamarTerisi: dashboard.kamarTerisi,
                items: dashboard.okupansiPerKos,
              ),
              const SizedBox(height: AppDesign.spaceLg),
            ],

            if (dashboard.tampilkanTagihanDetail) ...[
              const DashboardCategoryHeader(
                icon: Icons.receipt_long_rounded,
                title: 'Tagihan',
                subtitle: 'Status & prioritas',
              ),
              DashboardTagihanStatus(
                periodeLabel: dashboard.periodeLabel,
                statusTagihan: dashboard.statusTagihan,
              ),
              const SizedBox(height: AppDesign.spaceMd),
              DashboardTagihanAlert(items: dashboard.tagihanPerhatian),
              const SizedBox(height: AppDesign.spaceLg),
            ],

            if (dashboard.tampilkanAktivitasDetail) ...[
              const DashboardCategoryHeader(
                icon: Icons.history_rounded,
                title: 'Aktivitas',
                subtitle: 'Kejadian terbaru',
              ),
              DashboardActivityList(items: dashboard.aktivitasTerbaru),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;

  const _DashboardError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      decoration: BoxDecoration(
        color: AppDesign.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      ),
      child: Text(
        message,
        style: AppDesign.bodyMuted(context).copyWith(color: AppDesign.danger),
      ),
    );
  }
}
