import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_stat_card_compact.dart';

class DashboardKpiGrid extends StatelessWidget {
  final int jumlahKos;
  final int okupansiPersen;
  final int penyewaAktif;
  final int kontrakAktif;

  const DashboardKpiGrid({
    super.key,
    required this.jumlahKos,
    required this.okupansiPersen,
    required this.penyewaAktif,
    required this.kontrakAktif,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return GridView.count(
          crossAxisCount: compact ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppDesign.spaceSm,
          crossAxisSpacing: AppDesign.spaceSm,
          childAspectRatio: compact ? 2.6 : 1.35,
          children: [
            AppStatCardCompact(
              label: 'Total kos',
              value: '$jumlahKos',
              icon: Icons.home_work_outlined,
              iconColor: AppDesign.info,
            ),
            AppStatCardCompact(
              label: 'Okupansi',
              value: '$okupansiPersen%',
              icon: Icons.pie_chart_outline_rounded,
              iconColor: AppDesign.success,
            ),
            AppStatCardCompact(
              label: 'Penyewa aktif',
              value: '$penyewaAktif',
              icon: Icons.people_outline_rounded,
              iconColor: AppDesign.warning,
            ),
            AppStatCardCompact(
              label: 'Kontrak aktif',
              value: '$kontrakAktif',
              icon: Icons.description_outlined,
              iconColor: AppDesign.info,
            ),
          ],
        );
      },
    );
  }
}
