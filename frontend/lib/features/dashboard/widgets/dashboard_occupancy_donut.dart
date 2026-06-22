import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_donut_chart.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_section_card.dart';

/// Donut hunian: kamar terisi vs kosong.
class DashboardOccupancyDonut extends StatelessWidget {
  final int totalKamar;
  final int kamarTerisi;
  final int okupansiPersen;

  const DashboardOccupancyDonut({
    super.key,
    required this.totalKamar,
    required this.kamarTerisi,
    required this.okupansiPersen,
  });

  @override
  Widget build(BuildContext context) {
    final total = totalKamar < 0 ? 0 : totalKamar;
    final terisi = kamarTerisi.clamp(0, total);
    final kosong = total - terisi;
    final primary = Theme.of(context).colorScheme.primary;

    return DashboardSectionCard(
      title: 'Tingkat hunian',
      subtitle: '$okupansiPersen% kamar terisi',
      child: DashboardDonutChart(
        centerValue: '$okupansiPersen%',
        centerLabel: 'okupansi',
        segments: [
          DonutSegment(
            label: 'Terisi',
            value: terisi.toDouble(),
            color: primary,
          ),
          DonutSegment(
            label: 'Kosong',
            value: kosong.toDouble(),
            color: AppDesign.border,
          ),
        ],
      ),
    );
  }
}
