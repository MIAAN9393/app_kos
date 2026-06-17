import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppDesign.textTertiary),
            const SizedBox(height: AppDesign.spaceMd),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppDesign.titleBold(context),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDesign.spaceSm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppDesign.bodyMuted(context),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDesign.spaceLg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
