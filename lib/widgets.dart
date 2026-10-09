import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'models.dart';
import 'theme.dart';

class BloomCard extends StatelessWidget {
  const BloomCard(
      {super.key, required this.child, this.color = Colors.white, this.onTap});

  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: BloomColors.outlineVariant.withOpacity(0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    );
  }
}

class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.emoji});

  final String text;
  final String? emoji;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(emoji != null ? '$emoji  $text' : text,
            style: Theme.of(context).textTheme.titleLarge),
      );
}

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.decimal = true,
    this.helper,
    this.onChanged,
    this.focusNode,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool decimal;
  final String? helper;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9.,]' : r'[0-9]'))
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
        errorText: errorText,
      ),
    );
  }
}

/// Polja za sve mere, po dva u redu.
class MeasureFields extends StatelessWidget {
  const MeasureFields({super.key, required this.controllers, this.onChanged});

  final Map<Measure, TextEditingController> controllers;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < Measure.values.length; i += 2) {
      final pair = Measure.values.skip(i).take(2).toList();
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final m in pair) ...[
              if (m != pair.first) const SizedBox(width: 12),
              Expanded(
                child: NumberField(
                  controller: controllers[m]!,
                  label: m.title,
                  suffix: 'cm',
                  helper: m.hint,
                  onChanged: (_) => onChanged?.call(),
                ),
              ),
            ],
            if (pair.length == 1) ...[
              const SizedBox(width: 12),
              const Expanded(child: SizedBox())
            ],
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/// Strelica + promena; za kilažu i cm je manje = bolje.
class DeltaText extends StatelessWidget {
  const DeltaText(this.delta, this.unit, {super.key});

  final double delta;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final rounded = (delta * 10).round() / 10;
    final String text;
    final Color color;
    if (rounded < 0) {
      text = '▼ ${fmtD(rounded.abs())} $unit';
      color = BloomColors.mint;
    } else if (rounded > 0) {
      text = '▲ ${fmtD(rounded)} $unit';
      color = BloomColors.coral;
    } else {
      text = '= 0 $unit';
      color = BloomColors.onSurfaceVariant;
    }
    return Text(text.trim(),
        style:
            TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13));
  }
}

class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? BloomColors.primaryContainer : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: selected
                  ? BloomColors.primaryContainer
                  : BloomColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.titleMedium),
                      Text(subtitle,
                          style: t.bodyMedium
                              ?.copyWith(color: BloomColors.onSurfaceVariant)),
                    ]),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: BloomColors.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill(
      {super.key,
      required this.label,
      required this.value,
      this.color = BloomColors.container});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: numberStyle.copyWith(fontSize: 19)),
        ),
      ]),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow(
      {super.key,
      required this.color,
      required this.label,
      required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: t.bodyMedium
                    ?.copyWith(color: BloomColors.onSurfaceVariant))),
        Text(value, style: t.titleMedium),
      ]),
    );
  }
}

class KcalRing extends StatelessWidget {
  const KcalRing(
      {super.key,
      required this.progress,
      required this.center,
      required this.below,
      this.size = 150});

  final double progress;
  final String center;
  final String below;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(progress),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(center, style: numberStyle.copyWith(fontSize: 28)),
            Text(below, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
        arcRect,
        0,
        2 * pi,
        false,
        Paint()
          ..color = BloomColors.containerHigh
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (progress > 1) {
      paint.color = BloomColors.coral;
    } else {
      paint.shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [Color(0xFFE88AA8), Color(0xFFB98BDB), Color(0xFFE88AA8)],
      ).createShader(rect);
    }
    canvas.drawArc(arcRect, -pi / 2, 2 * pi * min(progress, 1.0), false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

class ChartPoint {
  const ChartPoint(this.epochDay, this.value);
  final int epochDay;
  final double value;
}

class LineChart extends StatelessWidget {
  const LineChart({super.key, required this.points, this.height = 220});

  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _LinePainter(points)));
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points);

  final List<ChartPoint> points;

  static const _label = TextStyle(
      fontFamily: 'Poppins', fontSize: 11, color: BloomColors.onSurfaceVariant);

  TextPainter _text(String s) => TextPainter(
      text: TextSpan(text: s, style: _label), textDirection: TextDirection.ltr)
    ..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const left = 44.0, right = 14.0, top = 10.0, bottom = 24.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    final minV = points.map((p) => p.value).reduce(min);
    final maxV = points.map((p) => p.value).reduce(max);
    final pad = max((maxV - minV) * 0.2, 0.5);
    final lo = minV - pad, hi = maxV + pad;
    final minX = points.first.epochDay, maxX = points.last.epochDay;
    double x(int d) =>
        left + (maxX == minX ? w / 2 : (d - minX) / (maxX - minX) * w);
    double y(double v) => top + (hi - v) / (hi - lo) * h;

    final grid = Paint()
      ..color = BloomColors.outlineVariant
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final v = lo + (hi - lo) * i / 3;
      final yy = y(v);
      for (double xx = left; xx < size.width - right; xx += 12) {
        canvas.drawLine(
            Offset(xx, yy), Offset(min(xx + 6, size.width - right), yy), grid);
      }
      final t = _text(fmtD(v));
      t.paint(canvas, Offset(left - t.width - 8, yy - t.height / 2));
    }

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final o = Offset(x(points[i].epochDay), y(points[i].value));
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    if (points.length > 1) {
      final fill = Path.from(path)
        ..lineTo(x(points.last.epochDay), top + h)
        ..lineTo(x(points.first.epochDay), top + h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BloomColors.primary.withOpacity(0.28),
              BloomColors.primary.withOpacity(0)
            ],
          ).createShader(Rect.fromLTWH(0, top, size.width, h)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = BloomColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final p in points) {
      final c = Offset(x(p.epochDay), y(p.value));
      canvas.drawCircle(c, 6, Paint()..color = Colors.white);
      canvas.drawCircle(c, 4, Paint()..color = BloomColors.primary);
    }

    final labels =
        points.length == 1 ? [points.first] : [points.first, points.last];
    for (var i = 0; i < labels.length; i++) {
      final t = _text(formatShortDate(labels[i].epochDay));
      final cx = x(labels[i].epochDay);
      double tx = cx - t.width / 2;
      if (labels.length > 1) {
        tx = i == 0 ? max(left - 6, tx) : min(size.width - t.width, tx);
      }
      t.paint(canvas, Offset(tx, size.height - t.height));
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

/// Uneto po danu, sa isprekidanom linijom cilja.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.days, required this.target});

  final List<(int, int)> days;
  final int target;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 150,
      width: double.infinity,
      child: CustomPaint(painter: _BarsPainter(days, target)));
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.days, this.target);

  final List<(int, int)> days;
  final int target;

  @override
  void paint(Canvas canvas, Size size) {
    const bottom = 20.0;
    final h = size.height - bottom;
    final maxV = max(days.map((d) => d.$2).fold(0, max), target) * 1.15;
    final slot = size.width / days.length;
    final barW = slot * 0.5;
    for (var i = 0; i < days.length; i++) {
      final (day, kcal) = days[i];
      final cx = slot * i + slot / 2;
      final r = Radius.circular(barW / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - barW / 2, 0, barW, h), r),
        Paint()..color = BloomColors.containerHigh,
      );
      if (kcal > 0 && maxV > 0) {
        final bh = kcal / maxV * h;
        final rect = Rect.fromLTWH(cx - barW / 2, h - bh, barW, bh);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, r),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: kcal > target
                  ? [BloomColors.coral, BloomColors.coral.withOpacity(0.7)]
                  : [BloomColors.primary, BloomColors.secondary],
            ).createShader(rect),
        );
      }
      final t = TextPainter(
        text: TextSpan(
          text: weekdaysShort[dateOf(day).weekday - 1],
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: BloomColors.onSurfaceVariant),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(canvas, Offset(cx - t.width / 2, size.height - t.height));
    }
    if (maxV > 0) {
      final ty = h - target / maxV * h;
      final p = Paint()
        ..color = BloomColors.secondary
        ..strokeWidth = 1.5;
      for (double xx = 0; xx < size.width; xx += 18) {
        canvas.drawLine(
            Offset(xx, ty), Offset(min(xx + 10, size.width), ty), p);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => true;
}

class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key, this.height = 8});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: height,
          backgroundColor: BloomColors.containerHigh,
          color: BloomColors.primary,
        ),
      );
}

/// Naslov ekrana ispod statusne trake.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding:
          EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 20, 8, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: t.headlineLarge),
        if (subtitle != null)
          Text(subtitle!,
              style:
                  t.bodyMedium?.copyWith(color: BloomColors.onSurfaceVariant)),
      ]),
    );
  }
}

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
      backgroundColor: BloomColors.onPrimaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
}
