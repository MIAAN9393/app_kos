import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

/// Blok section laporan: judul + baris stat (kartu konsisten app-wide).
class KeuanganLaporanSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<KeuanganLaporanBaris> baris;

  const KeuanganLaporanSection({
    super.key,
    required this.title,
    required this.icon,
    required this.baris,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: AppDesign.cardDecoration(),
      padding: const EdgeInsets.all(AppDesign.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                ),
                child: Icon(icon, size: 20, color: primary),
              ),
              const SizedBox(width: AppDesign.spaceSm),
              Expanded(
                child: Text(title, style: AppDesign.titleBold(context)),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spaceMd),
          for (var i = 0; i < baris.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDesign.spaceSm),
                child: Divider(height: 1, color: AppDesign.border),
              ),
            _barisRow(context, baris[i]),
          ],
        ],
      ),
    );
  }

  Widget _barisRow(BuildContext context, KeuanganLaporanBaris b) {
    final nilaiStyle = TextStyle(
      fontWeight: b.tebal ? FontWeight.w800 : FontWeight.w600,
      fontSize: b.tebal ? 15 : 14,
      color: b.warnaNilai ?? AppDesign.textPrimary,
    );

    Widget? leading = b.leading;
    if (leading == null && b.icon != null) {
      final color = b.warnaNilai ?? AppDesign.textSecondary;
      leading = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(b.icon, size: 16, color: color),
      );
    }

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: AppDesign.spaceSm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.label,
                style: AppDesign.bodyMuted(context).copyWith(
                  fontWeight: b.tebal ? FontWeight.w700 : FontWeight.w500,
                  color:
                      b.tebal ? AppDesign.textPrimary : AppDesign.textSecondary,
                  fontSize: b.tebal ? 14 : 13,
                ),
              ),
              if (b.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  b.subtitle!,
                  style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppDesign.spaceSm),
        Flexible(
          child: Text(
            b.nilai,
            textAlign: TextAlign.end,
            style: nilaiStyle,
          ),
        ),
      ],
    );

    if (!b.tebal) return row;

    return Container(
      padding: const EdgeInsets.all(AppDesign.spaceSm),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        border: Border.all(color: AppDesign.border),
      ),
      child: row,
    );
  }
}

class KeuanganLaporanBaris {
  final String label;
  final String nilai;
  final String? subtitle;
  final bool tebal;
  final Color? warnaNilai;
  final IconData? icon;
  final Widget? leading;

  const KeuanganLaporanBaris({
    required this.label,
    required this.nilai,
    this.subtitle,
    this.tebal = false,
    this.warnaNilai,
    this.icon,
    this.leading,
  });
}
