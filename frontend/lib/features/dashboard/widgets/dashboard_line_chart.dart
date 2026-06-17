import 'package:flutter/material.dart';
import 'package:kos_management/core/theme/app_design.dart';

class LineChartPoint {
  final String label;
  final double value;

  const LineChartPoint({required this.label, required this.value});
}

/// Line/area chart mulus reusable. Dipakai sebagai grafik utama dashboard.
class DashboardLineChart extends StatelessWidget {
  final List<LineChartPoint> points;
  final Color color;
  final double height;
  final bool tampilkanLabelX;
  final bool labelTerang;
  final String Function(double value)? valueLabelBuilder;

  const DashboardLineChart({
    super.key,
    required this.points,
    required this.color,
    this.height = 170,
    this.tampilkanLabelX = true,
    this.labelTerang = false,
    this.valueLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return SizedBox(height: height);

    final maxNilai = points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minNilai = points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final terakhir = points.last;

    final labelColor = labelTerang
        ? Colors.white.withValues(alpha: 0.85)
        : AppDesign.textSecondary;
    final labelKuat = labelTerang ? Colors.white : AppDesign.textPrimary;

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              points: points,
              maxNilai: maxNilai,
              minNilai: minNilai,
              lineColor: color,
              labelTerang: labelTerang,
              valueLabelBuilder: valueLabelBuilder,
            ),
          ),
        ),
        if (tampilkanLabelX) ...[
          const SizedBox(height: AppDesign.spaceSm),
          Row(
            children: [
              for (final p in points)
                Expanded(
                  child: Text(
                    p.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: p == terakhir
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: p == terakhir ? labelKuat : labelColor,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<LineChartPoint> points;
  final double maxNilai;
  final double minNilai;
  final Color lineColor;
  final bool labelTerang;
  final String Function(double value)? valueLabelBuilder;

  _LineChartPainter({
    required this.points,
    required this.maxNilai,
    required this.minNilai,
    required this.lineColor,
    required this.labelTerang,
    this.valueLabelBuilder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 18.0;
    const bottomPad = 6.0;
    final chartH = size.height - topPad - bottomPad;
    final stepX = points.length > 1
        ? size.width / (points.length - 1)
        : size.width;
    final range = (maxNilai - minNilai) == 0 ? 1.0 : (maxNilai - minNilai);

    double yFor(double v) => topPad + (1 - (v - minNilai) / range) * chartH;

    final pts = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(i * stepX, yFor(points[i].value)),
    ];

    // Grid horizontal.
    final gridColor = labelTerang
        ? Colors.white.withValues(alpha: 0.18)
        : AppDesign.border.withValues(alpha: 0.6);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartH * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Kurva mulus (Catmull-Rom → cubic).
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      linePath.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    // Area gradient.
    final fillPath = Path.from(linePath)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: labelTerang ? 0.45 : 0.32),
            lineColor.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Garis.
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Titik.
    for (var i = 0; i < pts.length; i++) {
      final terakhir = i == pts.length - 1;
      canvas.drawCircle(
        pts[i],
        terakhir ? 6 : 4,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        pts[i],
        terakhir ? 6 : 4,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = terakhir ? 3 : 2,
      );
    }

    // Label nilai titik terakhir.
    final last = pts.last;
    final tp = TextPainter(
      text: TextSpan(
        text:
            valueLabelBuilder?.call(points.last.value) ??
            _formatChartValue(points.last.value),
        style: TextStyle(
          color: labelTerang ? Colors.white : lineColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (last.dx - tp.width).clamp(0, size.width - tp.width),
        last.dy - tp.height - 8,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.points != points ||
      old.maxNilai != maxNilai ||
      old.minNilai != minNilai ||
      old.lineColor != lineColor ||
      old.labelTerang != labelTerang ||
      old.valueLabelBuilder != valueLabelBuilder;
}

String _formatChartValue(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  final abs = value.abs();
  final fixed = abs >= 1 ? value.toStringAsFixed(1) : value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
