import 'package:flutter/material.dart';

class AppLoadingOverlay extends StatelessWidget {
  final bool loading;
  final Widget child;

  const AppLoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.65),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
