import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One line on the chart, optionally with its monthly [target] drawn as a
/// lighter bar per month (vaxiCSR's "target reference bar").
class TrendSeries {
  final String name;
  final List<double> values;
  final Color color;
  final double? target;

  const TrendSeries({required this.name, required this.values, required this.color, this.target});
}

/// The line colours, cycled across however many series are drawn - only
/// shades of the app's red / green / black, darkest-contrast first.
const trendPalette = [
  AppPalette.red,
  AppPalette.greenText,
  AppPalette.black,
  AppPalette.redSoft,
  AppPalette.green,
  Color(0xFF8A8A8A),
  Color(0xFF8E1B1B),
  Color(0xFF2E5A10),
  Color(0xFFBDBDBD),
  Color(0xFF555555),
];

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String compactPeso(double v) {
  final a = v.abs();
  String trim(String s) => s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  if (a >= 1e6) return '${trim((v / 1e6).toStringAsFixed(1))}M';
  if (a >= 1e3) return '${trim((v / 1e3).toStringAsFixed(1))}K';
  return v.round().toString();
}

/// vaxiCSR's Monthly Sales Trend: Jan-Dec lines with dots, target bars,
/// a compact-₱ value axis and a legend. Tap to view it full screen.
class SalesTrendChart extends StatelessWidget {
  final List<TrendSeries> series;
  final double height;
  final bool enlargeOnTap;

  const SalesTrendChart({super.key, required this.series, this.height = 220, this.enlargeOnTap = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chart = SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(
          series: series,
          gridColor: scheme.outlineVariant.withValues(alpha: 0.45),
          labelColor: scheme.onSurfaceVariant,
          surface: scheme.surfaceContainer,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        enlargeOnTap
            ? GestureDetector(onTap: () => _enlarge(context), child: chart)
            : chart,
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final s in series)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 14, height: 4, decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(
                    s.target == null ? s.name : '${s.name} · target ${compactPeso(s.target!)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  void _enlarge(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        appBar: AppBar(title: const Text('Monthly Sales Trend')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
            child: LayoutBuilder(
              builder: (ctx, c) => SingleChildScrollView(
                child: SalesTrendChart(series: series, height: math.max(320, c.maxHeight - 120), enlargeOnTap: false),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class _TrendPainter extends CustomPainter {
  final List<TrendSeries> series;
  final Color gridColor;
  final Color labelColor;
  final Color surface;

  _TrendPainter({required this.series, required this.gridColor, required this.labelColor, required this.surface});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 44.0;
    const bottomPad = 22.0;
    const topPad = 8.0;
    final plot = Rect.fromLTRB(leftPad, topPad, size.width - 6, size.height - bottomPad);

    var maxV = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        maxV = math.max(maxV, v);
      }
      if (s.target != null) maxV = math.max(maxV, s.target!);
    }
    final yMax = _niceMax(maxV);

    final labelStyle = TextStyle(fontSize: 10, color: labelColor, fontWeight: FontWeight.w600);
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Horizontal grid + value labels.
    const ticks = 5;
    for (var i = 0; i <= ticks; i++) {
      final v = yMax * i / ticks;
      final y = plot.bottom - plot.height * i / ticks;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      _text(canvas, compactPeso(v), Offset(plot.left - 6, y), labelStyle, alignRight: true);
    }

    final slot = plot.width / 12;
    double xOf(int m) => plot.left + slot * (m + 0.5);
    double yOf(double v) => plot.bottom - (yMax == 0 ? 0 : v / yMax) * plot.height;

    for (var m = 0; m < 12; m++) {
      _text(canvas, _months[m], Offset(xOf(m), plot.bottom + 12), labelStyle, center: true);
    }

    // Target bars first (behind the lines), side by side within each month.
    final withTargets = series.where((s) => s.target != null).toList();
    if (withTargets.isNotEmpty) {
      final barW = math.min(10.0, slot * 0.7 / withTargets.length);
      for (var m = 0; m < 12; m++) {
        for (var i = 0; i < withTargets.length; i++) {
          final s = withTargets[i];
          final x = xOf(m) - barW * withTargets.length / 2 + barW * i;
          final r = RRect.fromRectAndRadius(Rect.fromLTRB(x, yOf(s.target!), x + barW - 1, plot.bottom), const Radius.circular(2));
          canvas.drawRRect(r, Paint()..color = Color.lerp(s.color, Colors.white, 0.68)!.withValues(alpha: 0.85));
        }
      }
    }

    for (final s in series) {
      final path = Path();
      for (var m = 0; m < 12 && m < s.values.length; m++) {
        final p = Offset(xOf(m), yOf(s.values[m]));
        m == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      for (var m = 0; m < 12 && m < s.values.length; m++) {
        final p = Offset(xOf(m), yOf(s.values[m]));
        canvas.drawCircle(p, 3.6, Paint()..color = surface);
        canvas.drawCircle(p, 3.6, Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    }
  }

  double _niceMax(double v) {
    if (v <= 0) return 1;
    final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final f in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]) {
      if (f * exp >= v) return f * exp;
    }
    return 10 * exp;
  }

  void _text(Canvas canvas, String s, Offset at, TextStyle style, {bool alignRight = false, bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    final dx = alignRight ? at.dx - tp.width : (center ? at.dx - tp.width / 2 : at.dx);
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.series != series || old.gridColor != gridColor;
}
