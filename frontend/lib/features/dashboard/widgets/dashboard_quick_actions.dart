import 'package:flutter/material.dart';
import 'package:kos_management/core/navigation/app_navigation.dart';
import 'package:kos_management/core/theme/app_design.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 360 ? 2 : 3;
        final itemWidth =
            (constraints.maxWidth - AppDesign.spaceSm * (columns - 1)) /
            columns;
        return Wrap(
          spacing: AppDesign.spaceSm,
          runSpacing: AppDesign.spaceSm,
          children: [
            _action(
              context,
              width: itemWidth,
              label: 'Tambah penyewa',
              icon: Icons.person_add_alt_1_rounded,
              color: primary,
              onTap: () => AppNavigation.toTambahPenyewaKontrak(context),
            ),
            _action(
              context,
              width: itemWidth,
              label: 'Kelola data',
              icon: Icons.tune_rounded,
              color: AppDesign.info,
              onTap: () => AppNavigation.toControllTab(context),
            ),
            _action(
              context,
              width: itemWidth,
              label: 'Keuangan',
              icon: Icons.account_balance_wallet_rounded,
              color: AppDesign.success,
              onTap: () => AppNavigation.toKeuanganTab(context),
            ),
          ],
        );
      },
    );
  }

  Widget _action(
    BuildContext context, {
    required double width,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppDesign.card,
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: AppDesign.cardDecoration(),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppDesign.bodyMuted(context).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppDesign.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
