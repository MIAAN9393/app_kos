import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';
import 'package:kos_management/core/widgets/app_hero_header.dart';

class AppPageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBarBottom;
  final bool showBack;
  final List<Widget>? heroStats;
  final Widget? trailing;

  const AppPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.floatingActionButton,
    this.appBarBottom,
    this.showBack = false,
    this.heroStats,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.surface,
      floatingActionButton: floatingActionButton,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBack)
            AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
              title: Text(title),
              bottom: appBarBottom,
            )
          else
            AppHeroHeader(
              title: title,
              subtitle: subtitle,
              trailing: trailing,
              stats: heroStats,
            ),
          if (appBarBottom != null && !showBack)
            Material(color: AppDesign.card, child: appBarBottom!),
          Expanded(child: body),
        ],
      ),
    );
  }
}
