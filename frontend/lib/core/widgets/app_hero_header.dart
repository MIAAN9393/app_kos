import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class AppHeroHeader extends StatelessWidget {
  /// Tinggi area judul (biru) — sama di Dashboard, Property, Laporan Keuangan.
  static const double toolbarMinHeight = 52;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget>? stats;

  const AppHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppDesign.spaceMd,
            AppDesign.spaceSm,
            AppDesign.spaceMd,
            AppDesign.spaceMd,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppDesign.radiusLg),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: toolbarMinHeight),
              child: trailing != null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _titleBlock(context)),
                        const SizedBox(width: AppDesign.spaceSm),
                        trailing!,
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: _titleBlock(context),
                    ),
            ),
          ),
        ),
        if (stats != null && stats!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDesign.spaceMd,
              AppDesign.spaceSm,
              AppDesign.spaceMd,
              AppDesign.spaceXs,
            ),
            child: Row(
              children: [
                for (var i = 0; i < stats!.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppDesign.spaceSm),
                  Expanded(child: stats![i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _titleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ],
    );
  }
}

/// Stat di bawah hero (area putih), bukan di atas background biru.
class AppHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const AppHeroStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spaceSm,
        vertical: 10,
      ),
      decoration: AppDesign.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
