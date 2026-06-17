import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppOutlinedAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;
  final Color? accentColor;

  const AppOutlinedAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = accentColor ?? Theme.of(context).colorScheme.primary;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? color : AppDesign.textSecondary,
        backgroundColor: compact && enabled
            ? color.withValues(alpha: 0.06)
            : compact
            ? Colors.grey.shade100
            : null,
        minimumSize: compact ? null : const Size.fromHeight(48),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : null,
        textStyle: compact
            ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
        ),
        side: BorderSide(
          color: compact && enabled
              ? color.withValues(alpha: 0.32)
              : AppDesign.border,
        ),
      ),
    );
  }
}
