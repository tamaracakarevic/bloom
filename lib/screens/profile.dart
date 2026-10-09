import 'package:flutter/material.dart';

import '../calc.dart';
import '../format.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.today});

  final int today;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _goal = TextEditingController();
  final _manual = TextEditingController();
  late ActivityLevel _activity;
  late Pace _pace;
  late bool _useManual;
  Profile? _loadedFrom;

  void _load(Profile p) {
    _loadedFrom = p;
    _name.text = p.name;
    _age.text = p.age.toString();
    _height.text = fmtD(p.heightCm);
    _goal.text = p.goalWeightKg == null ? '' : fmtD(p.goalWeightKg!);
    _manual.text = p.manualTargetKcal?.toString() ?? '';
    _activity = p.activity;
    _pace = p.pace;
    _useManual = p.manualTargetKcal != null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = AppScope.of(context);
    final profile = state.data.profile!;
    if (!identical(profile, _loadedFrom)) _load(profile);

    final age = parseNumber(_age.text)?.toInt();
    final height = parseNumber(_height.text);
    final manual = parseNumber(_manual.text)?.toInt();
    final valid = age != null &&
        age >= 14 &&
        age <= 99 &&
        height != null &&
        height >= 120 &&
        height <= 230 &&
        (!_useManual || (manual != null && manual >= 800));
    final edited = valid
        ? profile.copyWith(
            name: _name.text.trim(),
            age: age,
            heightCm: height,
            goalWeightKg: () => parseNumber(_goal.text),
            activity: _activity,
            pace: _pace,
            manualTargetKcal: () => _useManual ? manual : null,
          )
        : profile;
    final weight = state.data.currentWeight ?? profile.startWeightKg;
    void refresh(_) => setState(() {});

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const ScreenTitle('Profil'),
          const SizedBox(height: 16),
          BloomCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('Kalorijski cilj', emoji: '🎯'),
              LegendRow(
                color: BloomColors.outline,
                label: 'Bazalni metabolizam',
                value:
                    '${fmtI(Calc.bmr(weight, edited.heightCm, edited.age).round())} kcal',
              ),
              LegendRow(
                color: BloomColors.secondary,
                label: 'Održavanje (bez šetnje)',
                value: '${fmtI(Calc.maintenance(edited, weight))} kcal',
              ),
              LegendRow(
                color: BloomColors.mint,
                label: 'Preporuka za mršavljenje',
                value: '${fmtI(Calc.suggestedTarget(edited, weight))} kcal',
              ),
              const SizedBox(height: 6),
              Text(
                  'Računato za tvoju poslednju kilažu (${fmtD(weight)} kg) — ažurira se sa svakim merenjem.',
                  style: t.bodySmall),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: Text('Ručno postavljen cilj', style: t.titleMedium)),
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
                  onChanged: refresh,
                  errorText: manual != null && manual < 800
                      ? 'Najmanje 800 kcal'
                      : null,
                ),
            ]),
          ),
          const SizedBox(height: 16),
          BloomCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('O meni', emoji: '🌷'),
              TextField(
                controller: _name,
                onChanged: refresh,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ime'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: NumberField(
                        controller: _age,
                        label: 'Godine',
                        decimal: false,
                        onChanged: refresh)),
                const SizedBox(width: 12),
                Expanded(
                    child: NumberField(
                        controller: _height,
                        label: 'Visina',
                        suffix: 'cm',
                        onChanged: refresh)),
              ]),
              const SizedBox(height: 12),
              NumberField(
                  controller: _goal,
                  label: 'Ciljna kilaža',
                  suffix: 'kg',
                  onChanged: refresh),
              const SizedBox(height: 16),
              Text('Aktivnost (bez šetnje)', style: t.titleMedium),
              const SizedBox(height: 8),
              for (final a in ActivityLevel.values)
                SelectableCard(
                  selected: _activity == a,
                  title: a.title,
                  subtitle: a.subtitle,
                  onTap: () => setState(() => _activity = a),
                ),
              const SizedBox(height: 8),
              Text('Tempo', style: t.titleMedium),
              const SizedBox(height: 8),
              for (final p in Pace.values)
                SelectableCard(
                  selected: _pace == p,
                  title: p.title,
                  subtitle: '${p.subtitle} · −${p.deficit} kcal',
                  onTap: () => setState(() => _pace = p),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: valid && _differs(edited, profile)
                      ? () {
                          FocusScope.of(context).unfocus();
                          state.updateProfile(edited);
                          showToast(context, 'Sačuvano 🌸');
                        }
                      : null,
                  child: const Text('Sačuvaj promene'),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          if (state.steps.available || Reminders.supported) ...[
            BloomCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardTitle('Koraci i podsetnik', emoji: '👟'),
                    if (state.steps.available)
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Aplikacija Zdravlje',
                                    style: t.titleMedium),
                                Text(
                                  state.stepsLinked
                                      ? 'Povezano — koraci se čitaju automatski'
                                      : 'Nije povezano',
                                  style: t.bodySmall?.copyWith(
                                      color: state.stepsLinked
                                          ? BloomColors.mint
                                          : null),
                                ),
                              ]),
                        ),
                        OutlinedButton(
                          onPressed: () => state.connectSteps(widget.today),
                          child: Text(state.stepsLinked ? 'Ponovo' : 'Poveži'),
                        ),
                      ]),
                    if (state.steps.available && state.stepsLinked) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Ako koraci ostaju 0: Podešavanja → Zdravlje → Pristup podacima i uređaji → Bloom → uključi Koraci.',
                        style: t.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (Reminders.supported)
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Podsetnik za merenje',
                                    style: t.titleMedium),
                                Text('Obaveštenje kad prođe 7 dana',
                                    style: t.bodySmall),
                              ]),
                        ),
                        Switch(
                          value: profile.reminderEnabled,
                          onChanged: (on) async {
                            if (on) await Reminders.requestPermission();
                            state.updateProfile(
                                profile.copyWith(reminderEnabled: on));
                          },
                        ),
                      ]),
                  ]),
            ),
            const SizedBox(height: 16),
          ],
          BloomCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CardTitle('Rezervna kopija', emoji: '💾'),
              Text(
                'Podaci su samo na ovom telefonu. Povremeno sačuvaj kopiju (Sačuvaj → Save to Files / iCloud Drive) — '
                'ako obrišeš app ili promeniš telefon, odatle ih vraćaš.',
                style:
                    t.bodyMedium?.copyWith(color: BloomColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Builder(
                    builder: (btnContext) => OutlinedButton.icon(
                      onPressed: () {
                        final box = btnContext.findRenderObject() as RenderBox?;
                        final origin = box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size;
                        state.exportBackup(origin);
                      },
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Sačuvaj'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await state.importBackup();
                      if (context.mounted) {
                        showToast(
                            context,
                            ok
                                ? 'Podaci vraćeni 🌸'
                                : 'Uvoz nije uspeo ili je otkazan');
                      }
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Vrati'),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _confirmReset(context),
                child: const Text('Obriši sve podatke',
                    style: TextStyle(color: BloomColors.coral)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  bool _differs(Profile a, Profile b) =>
      a.toJson().toString() != b.toJson().toString();

  Future<void> _confirmReset(BuildContext context) async {
    final state = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obrisati sve?'),
        content: const Text(
            'Brišu se profil, sva merenja i kalorije. Ovo ne može da se vrati (osim iz rezervne kopije).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Otkaži')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Obriši sve',
                style: TextStyle(color: BloomColors.coral)),
          ),
        ],
      ),
    );
    if (ok == true) state.resetAll();
  }
}
