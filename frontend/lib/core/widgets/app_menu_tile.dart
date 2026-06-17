import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppMenuTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const AppMenuTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spaceSm),
      child: Material(
        color: AppDesign.card,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          child: Container(
            decoration: AppDesign.cardDecoration(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.spaceMd,
              vertical: AppDesign.spaceMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: AppDesign.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppDesign.titleBold(context)),
                      if (subtitle != null)
                        Text(subtitle!, style: AppDesign.bodyMuted(context)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppDesign.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
