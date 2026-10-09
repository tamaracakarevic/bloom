import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.day,
    required this.today,
    required this.onDayChange,
    required this.onGoMeasure,
  });

  final int day;
  final int today;
  final ValueChanged<int> onDayChange;
  final VoidCallback onGoMeasure;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final data = state.data;
    final profile = data.profile!;
    final weight = data.currentWeight ?? profile.startWeightKg;
    final log = data.day(day);
    final s = Calc.summarize(profile, weight, log);

    Widget padded(Widget w) =>
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: w);

    return ListView(
      padding: EdgeInsets.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _Header(
            name: profile.name,
            day: day,
            today: today,
            onDayChange: onDayChange),
        const SizedBox(height: 16),
        if (data.latest != null)
          padded(_MeasureReminder(
              lastDay: data.latest!.epochDay,
              today: today,
              onGoMeasure: onGoMeasure)),
        padded(_CaloriesCard(
            key: ValueKey('cal$day'), day: day, summary: s, foods: log.foods)),
        padded(_StepsCard(day: day, log: log, stepsKcal: s.stepsKcal)),
        padded(_BalanceCard(data: data, day: day)),
        padded(_WeightCard(data: data)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.name,
      required this.day,
      required this.today,
      required this.onDayChange});

  final String name;
  final int day;
  final int today;
  final ValueChanged<int> onDayChange;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 20, 24, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          name.isEmpty ? 'Zdravo, lepotice 🌸' : 'Zdravo, $name 🌸',
          style:
              t.headlineMedium?.copyWith(color: BloomColors.onPrimaryContainer),
        ),
        const SizedBox(height: 4),
        Text(quoteFor(day),
            style: t.bodyMedium?.copyWith(color: const Color(0xFF5B3A48))),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(50)),
          child: Row(children: [
            IconButton(
              onPressed: () => onDayChange(day - 1),
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Prethodni dan',
            ),
            Expanded(
                child: Text(formatRelativeDay(day, today),
                    style: t.titleMedium, textAlign: TextAlign.center)),
            IconButton(
              onPressed: day < today ? () => onDayChange(day + 1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Sledeći dan',
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MeasureReminder extends StatelessWidget {
  const _MeasureReminder(
      {required this.lastDay, required this.today, required this.onGoMeasure});

  final int lastDay;
  final int today;
  final VoidCallback onGoMeasure;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final since = today - lastDay;
    if (since >= Reminders.intervalDays) {
      return BloomCard(
        color: BloomColors.primaryContainer,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Vreme je za nedeljno merenje 📏', style: t.titleLarge),
          const SizedBox(height: 4),
          Text(
              'Prošlo je $since dana od poslednjeg merenja. Izmeri se ujutru, pre doručka.',
              style: t.bodyMedium),
          const SizedBox(height: 12),
          FilledButton(onPressed: onGoMeasure, child: const Text('Upiši mere')),
        ]),
      );
    }
    final left = Reminders.intervalDays - since;
    return BloomCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sledeće merenje', style: t.bodySmall),
              Text(left == 1 ? 'sutra' : 'za $left dana', style: t.titleLarge),
            ]),
          ),
          const Text('📏', style: TextStyle(fontSize: 28)),
        ]),
        const SizedBox(height: 12),
        ProgressBar(since / Reminders.intervalDays),
      ]),
    );
  }
}

class _CaloriesCard extends StatefulWidget {
  const _CaloriesCard(
      {super.key,
      required this.day,
      required this.summary,
      required this.foods});

  final int day;
  final DaySummary summary;
  final List<FoodItem> foods;

  @override
  State<_CaloriesCard> createState() => _CaloriesCardState();
}

class _CaloriesCardState extends State<_CaloriesCard> {
  final _label = TextEditingController();
  final _kcal = TextEditingController();
  final _labelFocus = FocusNode();

  void _submit() {
    final k = parseNumber(_kcal.text)?.toInt() ?? 0;
    if (k <= 0) return;
    AppScope.of(context).addFood(widget.day, _label.text, k);
    _label.clear();
    _kcal.clear();
    _labelFocus.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = widget.summary;
    final remaining = s.remaining;
    return BloomCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Kalorije', emoji: '🍓'),
        Row(children: [
          KcalRing(
            progress: s.budget > 0 ? s.eaten / s.budget : 0,
            center: remaining >= 0 ? fmtI(remaining) : '+${fmtI(-remaining)}',
            below: remaining >= 0 ? 'kcal preostalo' : 'kcal preko',
            size: 140,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(children: [
              LegendRow(
                  color: BloomColors.secondary,
                  label: 'Cilj',
                  value: fmtI(s.target)),
              LegendRow(
                  color: BloomColors.mint,
                  label: 'Koraci',
                  value: '+${fmtI(s.stepsKcal)}'),
              LegendRow(
                  color: BloomColors.primary,
                  label: 'Uneto',
                  value: fmtI(s.eaten)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _label,
              focusNode: _labelFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Šta si jela?'),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: NumberField(
                controller: _kcal,
                label: 'kcal',
                decimal: false,
                onChanged: (_) => setState(() {})),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: (parseNumber(_kcal.text) ?? 0) > 0 ? _submit : null,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Dodaj',
          ),
        ]),
        if (widget.foods.isNotEmpty) const SizedBox(height: 8),
        for (final f in widget.foods)
          Row(children: [
            Expanded(
              child: Text(f.label.isEmpty ? 'Obrok' : f.label,
                  style: t.bodyLarge, overflow: TextOverflow.ellipsis),
            ),
            Text('${fmtI(f.kcal)} kcal',
                style: t.titleSmall
                    ?.copyWith(color: BloomColors.onSurfaceVariant)),
            IconButton(
              onPressed: () =>
                  AppScope.of(context).removeFood(widget.day, f.id),
              icon: const Icon(Icons.close_rounded,
                  size: 18, color: BloomColors.outline),
              tooltip: 'Obriši',
            ),
          ]),
      ]),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard(
      {required this.day, required this.log, required this.stepsKcal});

  final int day;
  final DayLog log;
  final int stepsKcal;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = AppScope.of(context);
    final linked = state.stepsLinked;
    final source = log.manualSteps != null && state.steps.available
        ? ' · upisano ručno'
        : linked
            ? ' · iz aplikacije Zdravlje'
            : '';
    return BloomCard(
      onTap: state.steps.available ? null : () => _manualDialog(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Koraci', emoji: '👟'),
        Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(fmtI(log.steps), style: numberStyle.copyWith(fontSize: 34)),
              const SizedBox(width: 8),
              Text('koraka',
                  style: t.bodyLarge
                      ?.copyWith(color: BloomColors.onSurfaceVariant)),
            ]),
        Text('≈ ${fmtI(stepsKcal)} kcal potrošeno hodanjem$source',
            style: t.bodyMedium?.copyWith(color: BloomColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        if (!state.steps.available) ...[
          FilledButton.icon(
            onPressed: () => _manualDialog(context),
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(log.steps > 0 ? 'Izmeni korake' : 'Upiši korake'),
          ),
          const SizedBox(height: 6),
          Text('Prepiši broj koraka iz aplikacije Zdravlje (kartica Koraci).',
              style: t.bodySmall),
        ] else
          Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (linked)
                  OutlinedButton.icon(
                    onPressed: () => state.syncSteps(day),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Osveži'),
                  )
                else
                  FilledButton(
                      onPressed: () => state.connectSteps(day),
                      child: const Text('Poveži sa Zdravljem')),
                TextButton.icon(
                  onPressed: () => _manualDialog(context),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Upiši ručno'),
                ),
              ]),
        if (!linked && state.steps.available) ...[
          const SizedBox(height: 6),
          Text(
              'iPhone sam broji korake u aplikaciji Zdravlje — Bloom ih čita odatle.',
              style: t.bodySmall),
        ],
      ]),
    );
  }

  Future<void> _manualDialog(BuildContext context) async {
    final state = AppScope.of(context);
    final initial = log.manualSteps ?? (log.steps > 0 ? log.steps : null);
    final controller = TextEditingController(text: initial?.toString() ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broj koraka'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NumberField(
                  controller: controller, label: 'Koraci', decimal: false),
              const SizedBox(height: 8),
              if (state.steps.available)
                Text('Ručni unos ima prednost nad automatskim brojanjem.',
                    style: Theme.of(ctx).textTheme.bodySmall),
            ]),
        actions: [
          if (log.manualSteps != null)
            TextButton(
              onPressed: () {
                state.setManualSteps(day, null);
                Navigator.pop(ctx);
              },
              child: const Text('Ukloni ručni unos'),
            )
          else
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Otkaži')),
          TextButton(
            onPressed: () {
              state.setManualSteps(day, parseNumber(controller.text)?.toInt());
              Navigator.pop(ctx);
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.data, required this.day});

  final AppData data;
  final int day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = data.profile!;
    final weight = data.currentWeight ?? profile.startWeightKg;
    final s = Calc.summarize(profile, weight, data.day(day));
    final week = [
      for (var d = day - 6; d <= day; d++)
        Calc.summarize(profile, weight, data.day(d))
    ].where((x) => x.hasFood).toList();
    final kg = week.fold(0, (sum, x) => sum + x.deficit) / Calc.kcalPerKg;

    return BloomCard(
      color: s.hasFood && s.deficit > 0 ? BloomColors.mintSoft : Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Bilans dana', emoji: '⚖️'),
        if (!s.hasFood)
          Text('Upiši šta si jela i pokazaću ti koliki je deficit.',
              style: t.bodyLarge?.copyWith(color: BloomColors.onSurfaceVariant))
        else if (s.deficit > 0)
          Text('U deficitu si ≈ ${fmtI(s.deficit)} kcal 💪',
              style: t.titleLarge?.copyWith(color: BloomColors.mint))
        else ...[
          Text('≈ ${fmtI(-s.deficit)} kcal preko potrošnje',
              style: t.titleLarge?.copyWith(color: BloomColors.coral)),
          Text(
              'Nema veze — jedan dan ne menja ništa. Sutra je novi početak. 🌷',
              style: t.bodyMedium),
        ],
        const SizedBox(height: 6),
        Text(
            'Potrošeno ≈ ${fmtI(s.burned)} kcal (metabolizam + aktivnost + koraci)',
            style: t.bodySmall),
        if (week.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Poslednjih 7 dana (${week.length} upisano)',
              style: t.bodySmall),
          Text(kg >= 0 ? '≈ −${fmtD(kg, 2)} kg masti' : '≈ +${fmtD(-kg, 2)} kg',
              style: t.titleLarge),
        ],
      ]),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = data.profile!;
    final start = data.entries.isEmpty
        ? profile.startWeightKg
        : data.entries.first.weightKg;
    final current = data.currentWeight ?? start;
    final goal = profile.goalWeightKg;
    final progress = goal != null && start > goal
        ? ((start - current) / (start - goal)).clamp(0.0, 1.0)
        : null;

    return BloomCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const CardTitle('Kilaža', emoji: '🌷'),
        Row(children: [
          Expanded(
              child: StatPill(label: 'Početak', value: '${fmtD(start)} kg')),
          const SizedBox(width: 10),
          Expanded(
            child: StatPill(
                label: 'Sada',
                value: '${fmtD(current)} kg',
                color: BloomColors.primaryContainer),
          ),
          if (goal != null) ...[
            const SizedBox(width: 10),
            Expanded(child: StatPill(label: 'Cilj', value: '${fmtD(goal)} kg')),
          ],
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text('Od početka: ', style: t.bodyMedium),
          DeltaText(current - start, 'kg')
        ]),
        if (progress != null) ...[
          const SizedBox(height: 12),
          ProgressBar(progress, height: 10),
          const SizedBox(height: 6),
          Text(
              '${(progress * 100).round()}% puta do cilja${progress >= 1 ? ' — uspela si! 🎉' : ''}',
              style: t.bodySmall),
        ],
      ]),
    );
  }
}
