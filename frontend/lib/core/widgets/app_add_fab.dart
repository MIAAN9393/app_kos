import 'package:flutter/material.dart';

class AppAddFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final Object? heroTag;

  const AppAddFab({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      child: const Icon(Icons.add_rounded),
    );
  }
}
