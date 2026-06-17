import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_status_badge.dart';
import 'package:kos_management/features/dashboard/data/dashboard_dummy.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_section_card.dart';

class DashboardTagihanAlert extends StatelessWidget {
  final List<DashboardTagihanPerhatian> items;

  const DashboardTagihanAlert({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final data = items;

    return DashboardSectionCard(
      title: 'Perlu perhatian',
      subtitle: 'Tagihan prioritas',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppDesign.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${data.length}',
          style: const TextStyle(
            color: AppDesign.danger,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      child: Column(
        children: data.isEmpty
            ? [
                Text(
                  'Tidak ada tagihan prioritas',
                  style: AppDesign.bodyMuted(context),
                ),
              ]
            : [
                for (var i = 0; i < data.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AppDesign.spaceLg,
                      color: AppDesign.border,
                    ),
                  _row(context, data[i]),
                ],
              ],
      ),
    );
  }

  Widget _row(BuildContext context, DashboardTagihanPerhatian t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.penyewa,
                style: AppDesign.titleBold(context).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(t.kos, style: AppDesign.bodyMuted(context)),
              const SizedBox(height: 4),
              Text(
                'Jatuh tempo ${t.jatuhTempo}',
                style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDesign.spaceSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppDesign.formatRupiah(t.jumlah),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 6),
            AppStatusBadge(status: t.status),
          ],
        ),
      ],
    );
  }
}
