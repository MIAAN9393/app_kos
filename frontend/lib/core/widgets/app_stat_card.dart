import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesign.card,
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        child: Container(
          decoration: AppDesign.cardDecoration(),
          padding: const EdgeInsets.all(AppDesign.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(label, style: AppDesign.bodyMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
