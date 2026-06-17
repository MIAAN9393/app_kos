import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/dashboard/data/dashboard_dummy.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_section_card.dart';

class DashboardOccupancyBars extends StatelessWidget {
  final int totalKamar;
  final int kamarTerisi;
  final List<DashboardKosOkupansi> items;

  const DashboardOccupancyBars({
    super.key,
    required this.totalKamar,
    required this.kamarTerisi,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final data = items.isEmpty ? DashboardDummy.okupansiPerKos : items;
    final primary = Theme.of(context).colorScheme.primary;

    return DashboardSectionCard(
      title: 'Okupansi per kos',
      subtitle: '$kamarTerisi dari $totalKamar kamar terisi',
      child: Column(
        children: [
          for (var i = 0; i < data.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDesign.spaceMd),
            _barRow(context, data[i], primary),
          ],
        ],
      ),
    );
  }

  Widget _barRow(
    BuildContext context,
    DashboardKosOkupansi item,
    Color primary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.nama,
                style: AppDesign.titleBold(context).copyWith(fontSize: 14),
              ),
            ),
            Text(
              '${item.terisi}/${item.total}',
              style: AppDesign.bodyMuted(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '${item.persen}%',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: item.total == 0 ? 0 : item.terisi / item.total,
            minHeight: 8,
            backgroundColor: AppDesign.border,
            color: primary,
          ),
        ),
      ],
    );
  }
}
