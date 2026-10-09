import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets.dart';

/// [epochDay] null = novo merenje.
Future<void> openEntryEditor(BuildContext context, {int? epochDay}) {
  return Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => EntryEditorScreen(epochDay: epochDay),
  ));
}

class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final entries = state.data.entries;
    final reversed = entries.reversed.toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEntryEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo merenje',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: BloomColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const ScreenTitle('Merenja',
              subtitle: 'Jednom nedeljno, isti dan, ujutru pre doručka.'),
          const SizedBox(height: 12),
          for (final entry in reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EntryCard(
                entry: entry,
                previous: entries.indexOf(entry) > 0
                    ? entries[entries.indexOf(entry) - 1]
                    : null,
                isFirst: entries.indexOf(entry) == 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard(
      {required this.entry, required this.previous, required this.isFirst});

  final MeasurementEntry entry;
  final MeasurementEntry? previous;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final measured =
        Measure.values.where((m) => entry.value(m) != null).toList();
    return BloomCard(
      onTap: () => openEntryEditor(context, epochDay: entry.epochDay),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(formatDate(entry.epochDay), style: t.bodySmall),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Text('${fmtD(entry.weightKg)} kg',
                    style: numberStyle.copyWith(fontSize: 26)),
                const SizedBox(width: 10),
                if (previous != null)
                  DeltaText(entry.weightKg - previous!.weightKg, 'kg'),
                if (isFirst)
                  Text('početak 🌱',
                      style: t.labelLarge?.copyWith(
                          color: BloomColors.secondary,
                          fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded,
                color: BloomColors.outline),
            tooltip: 'Obriši',
          ),
        ]),
        if (measured.isNotEmpty) const SizedBox(height: 10),
        for (var i = 0; i < measured.length; i += 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              for (final m in measured.skip(i).take(2))
                Expanded(
                    child: _MeasureValue(
                        m: m,
                        value: entry.value(m)!,
                        previous: previous?.value(m))),
              if (measured.length - i == 1) const Expanded(child: SizedBox()),
            ]),
          ),
        if (entry.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(entry.note,
              style:
                  t.bodyMedium?.copyWith(color: BloomColors.onSurfaceVariant)),
        ],
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final state = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obrisati merenje?'),
        content:
            Text('Merenje od ${formatDate(entry.epochDay)} biće obrisano.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Otkaži')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Obriši')),
        ],
      ),
    );
    if (ok == true) state.deleteEntry(entry.epochDay);
  }
}

class _MeasureValue extends StatelessWidget {
  const _MeasureValue(
      {required this.m, required this.value, required this.previous});

  final Measure m;
  final double value;
  final double? previous;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(children: [
      Text('${m.title} ',
          style: t.bodyMedium?.copyWith(color: BloomColors.onSurfaceVariant)),
      Text(fmtD(value),
          style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      if (previous != null) ...[
        const SizedBox(width: 6),
        DeltaText(value - previous!, '')
      ],
    ]);
  }
}

class EntryEditorScreen extends StatefulWidget {
  const EntryEditorScreen({super.key, this.epochDay});

  final int? epochDay;

  @override
  State<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends State<EntryEditorScreen> {
  late int _day;
  final _weight = TextEditingController();
  final _note = TextEditingController();
  final _measures = {
    for (final m in Measure.values) m: TextEditingController()
  };
  MeasurementEntry? _initial;
  MeasurementEntry? _previous;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final data = AppScope.of(context).data;
    _initial = widget.epochDay == null
        ? null
        : data.entries.where((e) => e.epochDay == widget.epochDay).firstOrNull;
    _previous = data.latest;
    _day = _initial?.epochDay ?? today();
    if (_initial != null) {
      _weight.text = fmtD(_initial!.weightKg);
      _note.text = _initial!.note;
      for (final m in Measure.values) {
        final v = _initial!.value(m);
        if (v != null) _measures[m]!.text = fmtD(v);
      }
    }
  }

  double? get _weightN => parseNumber(_weight.text);

  void _save() {
    final values = <String, double>{
      for (final e in _measures.entries)
        if (parseNumber(e.value.text) != null)
          e.key.key: parseNumber(e.value.text)!,
    };
    AppScope.of(context).saveEntry(
      MeasurementEntry(
          epochDay: _day,
          weightKg: _weightN!,
          values: values,
          note: _note.text.trim()),
      _initial?.epochDay,
    );
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateOf(_day),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _day = epochDayOf(picked));
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final w = _weightN;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: BloomColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded)),
        title: Text(_initial == null ? 'Novo merenje' : 'Izmena merenja',
            style: t.titleLarge),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: w != null && w >= 30 && w <= 300 ? _save : null,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Sačuvaj'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(formatDate(_day)),
              ),
            ),
            const SizedBox(height: 14),
            NumberField(
              controller: _weight,
              label: 'Kilaža',
              suffix: 'kg',
              helper: _initial == null && _previous != null
                  ? 'Prošli put: ${fmtD(_previous!.weightKg)} kg'
                  : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Text('Mere', style: t.titleLarge),
            const SizedBox(height: 12),
            MeasureFields(controllers: _measures),
            const SizedBox(height: 4),
            TextField(
              controller: _note,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Beleška (kako se osećaš, ciklus…)'),
            ),
          ],
        ),
      ),
    );
  }
}
