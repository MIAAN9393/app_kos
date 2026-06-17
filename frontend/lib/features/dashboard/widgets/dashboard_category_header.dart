import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

/// Judul kategori antar grup section di dashboard.
class DashboardCategoryHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const DashboardCategoryHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(
        top: AppDesign.spaceXs,
        bottom: AppDesign.spaceSm,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: AppDesign.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppDesign.sectionTitle(context).copyWith(fontSize: 18),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
