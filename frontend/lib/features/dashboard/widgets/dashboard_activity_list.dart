import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/dashboard/data/dashboard_dummy.dart';
import 'package:kos_management/features/dashboard/widgets/dashboard_section_card.dart';

class DashboardActivityList extends StatelessWidget {
  final List<DashboardAktivitas> items;

  const DashboardActivityList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final data = items;

    return DashboardSectionCard(
      title: 'Aktivitas terbaru',
      subtitle: 'Alur operasional terbaru',
      child: Column(
        children: data.isEmpty
            ? [
                Text(
                  'Belum ada aktivitas terbaru',
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
                  _tile(context, data[i]),
                ],
              ],
      ),
    );
  }

  Widget _tile(BuildContext context, DashboardAktivitas a) {
    final meta = _ikonMeta(a.ikon);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: meta.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          ),
          child: Icon(meta.icon, size: 20, color: meta.color),
        ),
        const SizedBox(width: AppDesign.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.judul,
                style: AppDesign.titleBold(context).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(a.detail, style: AppDesign.bodyMuted(context)),
              const SizedBox(height: 4),
              Text(
                a.waktu,
                style: AppDesign.bodyMuted(
                  context,
                ).copyWith(fontSize: 11, color: AppDesign.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ({IconData icon, Color color}) _ikonMeta(String tipe) {
    switch (tipe) {
      case 'pembayaran':
        return (icon: Icons.payments_outlined, color: AppDesign.success);
      case 'kontrak':
        return (icon: Icons.assignment_outlined, color: AppDesign.info);
      case 'tagihan':
        return (icon: Icons.receipt_long_outlined, color: AppDesign.warning);
      default:
        return (
          icon: Icons.notifications_outlined,
          color: AppDesign.textSecondary,
        );
    }
  }
}
