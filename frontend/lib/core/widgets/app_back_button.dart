import 'package:flutter/material.dart';

/// Tombol kembali bulat — latar primary biru aplikasi, ikon putih.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
