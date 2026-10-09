import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.today});

  final int today;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  /// null = kilaža
  Measure? _metric;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final data = AppScope.of(context).data;
    final profile = data.profile!;
    final entries = data.entries;
    final available = Measure.values
        .where((m) => entries.any((e) => e.value(m) != null))
        .toList();
    final metric = available.contains(_metric) ? _metric : null;
    final points = metric == null
        ? [for (final e in entries) ChartPoint(e.epochDay, e.weightKg)]
        : [
            for (final e in entries)
              if (e.value(metric) != null)
                ChartPoint(e.epochDay, e.value(metric)!)
          ];
    final unit = metric == null ? 'kg' : 'cm';
    final weight = data.currentWeight ?? profile.startWeightKg;
    final target = Calc.target(profile, weight);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const ScreenTitle('Napredak',
            subtitle: 'Gledaj trend, ne pojedinačan dan. 🌸'),
        const SizedBox(height: 16),
        _TotalLossCard(data: data),
        const SizedBox(height: 16),
        BloomCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Kilaža', metric == null,
                    () => setState(() => _metric = null)),
                for (final m in available)
                  _chip(
                      m.title, metric == m, () => setState(() => _metric = m)),
              ]),
            ),
            const SizedBox(height: 12),
            if (points.length < 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Grafikon se pojavljuje posle drugog merenja.',
                    style: t.bodyMedium
                        ?.copyWith(color: BloomColors.onSurfaceVariant)),
              ),
            if (points.isNotEmpty) ...[
              LineChart(points: points),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: StatPill(
                        label: 'Početak',
                        value: '${fmtD(points.first.value)} $unit')),
                const SizedBox(width: 10),
                Expanded(
                  child: StatPill(
                    label: 'Sada',
                    value: '${fmtD(points.last.value)} $unit',
                    color: BloomColors.primaryContainer,
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text('Ukupna promena: ', style: t.bodyMedium),
                DeltaText(points.last.value - points.first.value, unit),
              ]),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        BloomCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const CardTitle('Kalorije ove nedelje', emoji: '🍓'),
            WeekBars(
              days: [
                for (var d = widget.today - 6; d <= widget.today; d++)
                  (d, data.day(d).eaten)
              ],
              target: target,
            ),
            const SizedBox(height: 8),
            Text('Isprekidana linija je tvoj cilj od ${fmtI(target)} kcal.',
                style: t.bodySmall),
          ]),
        ),
        const SizedBox(height: 16),
        _BodyStatsCard(data: data),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: BloomColors.primary,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : BloomColors.onSurfaceVariant,
          ),
          shape: StadiumBorder(
              side: BorderSide(
                  color: selected ? BloomColors.primary : BloomColors.outline)),
        ),
      );
}

class _TotalLossCard extends StatelessWidget {
  const _TotalLossCard({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (data.entries.isEmpty) return const SizedBox();
    final first = data.entries.first, last = data.entries.last;
    final kg = first.weightKg - last.weightKg;
    // svaka mera od prvog merenja u kom postoji do poslednjeg
    var cm = 0.0;
    for (final m in Measure.values) {
      final withValue = data.entries.where((e) => e.value(m) != null);
      if (withValue.isNotEmpty)
        cm += withValue.first.value(m)! - withValue.last.value(m)!;
    }
    final weeks = (last.epochDay - first.epochDay) ~/ 7;
    final good = kg > 0 || cm > 0;

    Widget big(String value, String label) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style:
                  numberStyle.copyWith(fontSize: 30, color: BloomColors.mint)),
          Text(label, style: t.bodySmall),
        ]);

    return BloomCard(
      color: good ? BloomColors.mintSoft : Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            weeks > 0
                ? 'Za ${weeksText(weeks, accusative: true)} si izgubila'
                : 'Tvoj put tek počinje ✨',
            style: t.titleMedium),
        const SizedBox(height: 6),
        Row(children: [
          big('${fmtD(kg < 0 ? 0 : kg)} kg', 'kilaže'),
          const SizedBox(width: 28),
          big('${fmtD(cm < 0 ? 0 : cm)} cm', 'ukupno sa svih mera'),
        ]),
      ]),
    );
  }
}

class _BodyStatsCard extends StatelessWidget {
  const _BodyStatsCard({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final profile = data.profile!;
    final latest = data.latest;
    if (latest == null) return const SizedBox();
    final bmi = Calc.bmi(latest.weightKg, profile.heightCm);
    double? lastValue(Measure m) {
      final withValue = data.entries.where((e) => e.value(m) != null);
      return withValue.isEmpty ? null : withValue.last.value(m);
    }

    final waist = lastValue(Measure.waist), hips = lastValue(Measure.hips);
    final weeks = Calc.weeksToGoal(profile, latest.weightKg);

    return BloomCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Tvoje telo u brojkama', emoji: '💗'),
        _line(context, 'BMI', '${fmtD(bmi)} · ${Calc.bmiLabel(bmi)}'),
        if (waist != null && hips != null)
          _line(context, 'Struk / bokovi',
              '${fmtD(Calc.waistToHip(waist, hips), 2)} · ${Calc.waistToHipLabel(Calc.waistToHip(waist, hips))}'),
        _line(context, 'Bazalni metabolizam',
            '${fmtI(Calc.bmr(latest.weightKg, profile.heightCm, profile.age).round())} kcal'),
        if (weeks != null && weeks > 0)
          _line(context, 'Do cilja okvirno', weeksText(weeks.round())),
      ]),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: t.bodyMedium
                    ?.copyWith(color: BloomColors.onSurfaceVariant))),
        Text(value, style: t.titleMedium),
      ]),
    );
  }
}
