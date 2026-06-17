import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppDocumentActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  const AppDocumentActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final textStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
    );

    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: 32,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppDesign.info,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppDesign.info.withValues(alpha: 0.55),
            disabledForegroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: radius),
            textStyle: textStyle,
          ),
          icon: Icon(icon, size: 16),
          label: Text(label),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDesign.textTertiary,
          disabledForegroundColor: AppDesign.textTertiary,
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white,
          side: const BorderSide(color: AppDesign.border),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textStyle,
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}
