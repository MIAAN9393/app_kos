import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class DonutSegment {
  final String label;
  final double value;
  final Color color;

  const DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Donut chart + legend reusable (dipakai untuk hunian & status tagihan).
class DashboardDonutChart extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  final double size;

  const DashboardDonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 132,
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<double>(0, (s, e) => s + e.value);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutPainter(segments: segments, total: total),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    centerValue,
                    style: AppDesign.sectionTitle(
                      context,
                    ).copyWith(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    centerLabel,
                    style: AppDesign.bodyMuted(context).copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDesign.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < segments.length; i++) ...[
                if (i > 0) const SizedBox(height: AppDesign.spaceSm),
                _legendRow(context, segments[i], total),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(BuildContext context, DonutSegment s, double total) {
    final persen = total == 0 ? 0 : (s.value / total * 100).round();
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: s.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppDesign.spaceSm),
        Expanded(
          child: Text(
            s.label,
            style: AppDesign.bodyMuted(
              context,
            ).copyWith(fontSize: 13, color: AppDesign.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${s.value.toInt()}',
          style: AppDesign.titleBold(context).copyWith(fontSize: 14),
        ),
        const SizedBox(width: 6),
        Text(
          '· $persen%',
          style: AppDesign.bodyMuted(context).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double total;

  _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    // Track latar.
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = AppDesign.border.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (total <= 0) return;

    var start = -math.pi / 2;
    const gap = 0.04; // celah antar segmen (radian)
    for (final s in segments) {
      if (s.value <= 0) continue;
      final sweep = (s.value / total) * (2 * math.pi) - gap;
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep < 0 ? 0 : sweep,
        false,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      start += (s.value / total) * (2 * math.pi);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.total != total;
  }
}
