import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/dashboard/data/dashboard_dummy.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_line_chart.dart';

/// Grafik utama dashboard — kartu pendapatan menonjol di paling atas.
class DashboardFeaturedRevenue extends StatelessWidget {
  final String periodeLabel;
  final int pendapatanBulanIni;
  final int pendapatanBulanLalu;
  final int deltaPendapatanPersen;
  final List<DashboardTrendBulan> trendPendapatan;
  final bool tampilkanTrend;

  const DashboardFeaturedRevenue({
    super.key,
    required this.periodeLabel,
    required this.pendapatanBulanIni,
    required this.pendapatanBulanLalu,
    required this.deltaPendapatanPersen,
    required this.trendPendapatan,
    this.tampilkanTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final trend = trendPendapatan;
    final delta = deltaPendapatanPersen;
    final naik = delta >= 0;

    final points = [
      for (final t in trend) LineChartPoint(label: t.bulan, value: t.nilai),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesign.spaceLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, Color.lerp(primary, Colors.black, 0.28)!],
        ),
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pendapatan $periodeLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      naik
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${naik ? '+' : ''}$delta%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppDesign.formatRupiah(pendapatanBulanIni),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bulan lalu ${AppDesign.formatRupiah(pendapatanBulanLalu)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          if (tampilkanTrend) ...[
            const SizedBox(height: AppDesign.spaceMd),
            if (points.isEmpty)
              Text(
                'Trend pendapatan belum tersedia',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              )
            else
              DashboardLineChart(
                points: points,
                color: Colors.white,
                labelTerang: true,
                height: 150,
                valueLabelBuilder: (value) => '${_formatJuta(value)} jt',
              ),
          ],
        ],
      ),
    );
  }

  String _formatJuta(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    final abs = value.abs();
    final fixed = abs >= 1
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
  }
}
