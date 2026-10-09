import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = 5;

  int _step = 0;
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goal = TextEditingController();
  final _manual = TextEditingController();
  final _measures = {
    for (final m in Measure.values) m: TextEditingController()
  };
  var _activity = ActivityLevel.light;
  var _pace = Pace.steady;
  var _useManual = false;

  int? get _ageN => parseNumber(_age.text)?.toInt();
  double? get _heightN => parseNumber(_height.text);
  double? get _weightN => parseNumber(_weight.text);

  bool get _bodyValid {
    final a = _ageN, h = _heightN, w = _weightN;
    return a != null &&
        a >= 14 &&
        a <= 99 &&
        h != null &&
        h >= 120 &&
        h <= 230 &&
        w != null &&
        w >= 30 &&
        w <= 300;
  }

  bool get _canContinue => switch (_step) {
        1 => _bodyValid,
        4 => !_useManual || (parseNumber(_manual.text)?.toInt() ?? 0) >= 800,
        _ => true,
      };

  Profile _profile() => Profile(
        name: _name.text.trim(),
        age: _ageN ?? 30,
        heightCm: _heightN ?? 165,
        startWeightKg: _weightN ?? 65,
        goalWeightKg: parseNumber(_goal.text),
        activity: _activity,
        pace: _pace,
        manualTargetKcal:
            _useManual ? parseNumber(_manual.text)?.toInt() : null,
        startEpochDay: today(),
      );

  Future<void> _finish() async {
    final state = AppScope.of(context);
    await Reminders.requestPermission();
    final values = <String, double>{
      for (final e in _measures.entries)
        if (parseNumber(e.value.text) != null)
          e.key.key: parseNumber(e.value.text)!,
    };
    state.completeOnboarding(
        _profile(),
        MeasurementEntry(
            epochDay: today(), weightKg: _weightN ?? 65, values: values));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _step ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? BloomColors.primary
                          : BloomColors.outlineVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: _content(t),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 16),
              child: Row(children: [
                if (_step > 0)
                  TextButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Nazad')),
                if (_step == 3)
                  TextButton(
                      onPressed: () => setState(() => _step++),
                      child: const Text('Preskoči')),
                const Spacer(),
                FilledButton(
                  onPressed: _canContinue
                      ? () {
                          FocusScope.of(context).unfocus();
                          if (_step < _steps - 1) {
                            setState(() => _step++);
                          } else {
                            _finish();
                          }
                        }
                      : null,
                  child: Text(_step == _steps - 1 ? 'Kreni 🌸' : 'Dalje'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _content(TextTheme t) {
    void refresh(_) => setState(() {});
    const gap = SizedBox(height: 14);
    switch (_step) {
      case 0:
        return [
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                  gradient: headerGradient, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('🌸', style: TextStyle(fontSize: 64)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Dobrodošla u Bloom',
              style: t.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Tvoj lični dnevnik kilaže, mera i kalorija. Jednom nedeljno upišeš mere, a svaki dan '
            'kalorije i korake — ja ti pokazujem koliko lepo napreduješ. 💕',
            style: t.bodyLarge?.copyWith(color: BloomColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Kako da te zovem?'),
          ),
        ];
      case 1:
        return [
          ..._title(t, 'Malo o tebi',
              'Treba mi za proračun kalorija. Sve ostaje samo na tvom telefonu.'),
          NumberField(
              controller: _age,
              label: 'Godine',
              decimal: false,
              onChanged: refresh),
          gap,
          NumberField(
              controller: _height,
              label: 'Visina',
              suffix: 'cm',
              onChanged: refresh),
          gap,
          NumberField(
              controller: _weight,
              label: 'Trenutna kilaža',
              suffix: 'kg',
              onChanged: refresh),
          gap,
          NumberField(
              controller: _goal,
              label: 'Ciljna kilaža (nije obavezno)',
              suffix: 'kg',
              onChanged: refresh),
        ];
      case 2:
        return [
          ..._title(t, 'Koliko si aktivna?',
              'Ne računaj šetnju — korake beležimo posebno svaki dan.'),
          for (final a in ActivityLevel.values)
            SelectableCard(
              selected: _activity == a,
              title: a.title,
              subtitle: a.subtitle,
              onTap: () => setState(() => _activity = a),
            ),
          const SizedBox(height: 16),
          Text('Kojim tempom želiš da mršaš?', style: t.titleLarge),
          const SizedBox(height: 12),
          for (final p in Pace.values)
            SelectableCard(
              selected: _pace == p,
              title: p.title,
              subtitle: '${p.subtitle} · −${p.deficit} kcal dnevno',
              onTap: () => setState(() => _pace = p),
            ),
        ];
      case 3:
        return [
          ..._title(t, 'Početne mere',
              'Meri se metrom, ujutru, pre doručka. Upiši šta želiš — sve je opciono i možeš kasnije.'),
          MeasureFields(controllers: _measures),
        ];
      default:
        final p = _profile();
        final w = p.startWeightKg;
        final weeks = Calc.weeksToGoal(p, w);
        return [
          ..._title(
              t, 'Tvoj plan 🌸', 'Okvirni proračun (Mifflin-St Jeor formula).'),
          BloomCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LegendRow(
                color: BloomColors.outline,
                label: 'Bazalni metabolizam',
                value: '${fmtI(Calc.bmr(w, p.heightCm, p.age).round())} kcal',
              ),
              LegendRow(
                color: BloomColors.secondary,
                label: 'Održavanje (bez šetnje)',
                value: '${fmtI(Calc.maintenance(p, w))} kcal',
              ),
              const SizedBox(height: 14),
              Text('Preporučeno za mršavljenje', style: t.bodySmall),
              Text(
                '${fmtI(Calc.suggestedTarget(p.copyWith(manualTargetKcal: () => null), w))} kcal',
                style: numberStyle.copyWith(
                    fontSize: 34, color: BloomColors.primary),
              ),
              Text('dnevno + kalorije koje zaradiš koracima',
                  style: t.bodyMedium
                      ?.copyWith(color: BloomColors.onSurfaceVariant)),
              TargetNotes(
                  profile: p.copyWith(manualTargetKcal: () => null),
                  weightKg: w),
              if (weeks != null && weeks > 0) ...[
                const SizedBox(height: 10),
                Text(
                    'Do cilja okvirno ${weeksText(weeks.round())}. Polako i sigurno. ✨',
                    style: t.bodyMedium),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child:
                    Text('Želim sama da postavim cilj', style: t.titleMedium)),
            Switch(
                value: _useManual,
                onChanged: (v) => setState(() => _useManual = v)),
          ]),
          if (_useManual)
            NumberField(
                controller: _manual,
                label: 'Dnevni cilj',
                suffix: 'kcal',
                decimal: false,
                onChanged: refresh),
          if (_useManual && p.manualTargetKcal != null)
            TargetNotes(profile: p, weightKg: w),
        ];
    }
  }

  List<Widget> _title(TextTheme t, String title, String subtitle) => [
        Text(title, style: t.headlineMedium),
        const SizedBox(height: 6),
        Text(subtitle,
            style: t.bodyLarge?.copyWith(color: BloomColors.onSurfaceVariant)),
        const SizedBox(height: 20),
      ];
}
