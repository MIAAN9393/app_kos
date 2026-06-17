import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/features/auth/widget/custom_appsnackbar.dart';

/// Tombol ikon di app bar detail — warna normal jika boleh, abu-abu jika tidak.
class AppEntityIconAction extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color activeColor;
  final VoidCallback? onPressed;
  final String? blockedMessage;
  final bool filled;
  final double size;

  const AppEntityIconAction({
    super.key,
    required this.icon,
    required this.enabled,
    this.activeColor = AppDesign.info,
    this.onPressed,
    this.blockedMessage,
    this.filled = true,
    this.size = 40,
  });

  void _handleTap(BuildContext context) {
    if (enabled && onPressed != null) {
      onPressed!();
      return;
    }
    final msg = blockedMessage?.trim();
    if (msg != null && msg.isNotEmpty) {
      AppSnackbar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled ? activeColor : AppDesign.textTertiary;
    return Material(
      color: filled
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.92)
          : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => _handleTap(context),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

/// OutlinedButton edit/hapus di tab detail — styling selaras dengan list card.
class AppEntityOutlinedAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color activeColor;
  final VoidCallback? onPressed;
  final String? blockedMessage;

  const AppEntityOutlinedAction({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.activeColor,
    this.onPressed,
    this.blockedMessage,
  });

  void _handleTap(BuildContext context) {
    if (enabled && onPressed != null) {
      onPressed!();
      return;
    }
    final msg = blockedMessage?.trim();
    if (msg != null && msg.isNotEmpty) {
      AppSnackbar.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = enabled ? activeColor : AppDesign.textTertiary;
    return OutlinedButton.icon(
      onPressed: () => _handleTap(context),
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: enabled ? 0.5 : 0.35)),
      ),
    );
  }
}
