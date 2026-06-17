import 'package:flutter/material.dart';

/// Design tokens — Material 3, Airbnb-inspired SaaS.
class AppDesign {
  static const Color surface = Color(0xFFF5F7FA);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color success = Color(0xFF16A34A);
  static const Color info = Color(0xFF2563EB);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;

  static EdgeInsets get pagePadding =>
      const EdgeInsets.symmetric(horizontal: spaceMd);

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static TextStyle titleBold(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ) ??
      const TextStyle(fontWeight: FontWeight.w700, fontSize: 16);

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ) ??
      const TextStyle(fontWeight: FontWeight.w700, fontSize: 20);

  static TextStyle bodyMuted(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textSecondary,
            height: 1.5,
          ) ??
      const TextStyle(color: textSecondary, height: 1.5);

  static String formatRupiah(dynamic value) {
    final n = int.tryParse('$value') ?? 0;
    final s = n.toString();
    final buffer = StringBuffer('Rp ');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
