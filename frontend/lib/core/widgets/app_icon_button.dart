import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.filled = true,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.92)
          : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(width: size, height: size, child: Icon(icon, size: 22)),
      ),
    );
  }
}
