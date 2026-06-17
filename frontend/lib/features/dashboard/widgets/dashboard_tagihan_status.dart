import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/dashboard/data/dashboard_dummy.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_donut_chart.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_section_card.dart';

/// Donut rincian status tagihan periode ini.
class DashboardTagihanStatus extends StatelessWidget {
  final String periodeLabel;
  final List<DashboardStatusTagihan> statusTagihan;

  const DashboardTagihanStatus({
    super.key,
    required this.periodeLabel,
    required this.statusTagihan,
  });

  static const Color _orange = Color(0xFFEA580C);

  Color _warna(String status) {
    switch (status) {
      case 'lunas':
        return AppDesign.success;
      case 'sebagian':
        return _orange;
      case 'belum_bayar':
        return AppDesign.warning;
      case 'telat':
        return AppDesign.danger;
      default:
        return AppDesign.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = statusTagihan.isEmpty
        ? DashboardDummy.statusTagihan
        : statusTagihan;
    final total = data.fold<int>(0, (s, e) => s + e.jumlah);

    return DashboardSectionCard(
      title: 'Status tagihan',
      subtitle: 'Periode $periodeLabel',
      child: DashboardDonutChart(
        centerValue: '$total',
        centerLabel: 'tagihan',
        segments: [
          for (final s in data)
            DonutSegment(
              label: s.label,
              value: s.jumlah.toDouble(),
              color: _warna(s.status),
            ),
        ],
      ),
    );
  }
}
