import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services.dart';

class AppState extends ChangeNotifier {
  AppState._(this._prefs, this._data, this._stepsLinked);

  static const _keyData = 'data';
  static const _keyStepsLinked = 'steps_linked';

  final SharedPreferences _prefs;
  final steps = StepsService();
  AppData _data;
  bool _stepsLinked;

  AppData get data => _data;
  bool get stepsLinked => _stepsLinked;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    var data = const AppData();
    final raw = prefs.getString(_keyData);
    if (raw != null) {
      try {
        data = AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final state = AppState._(prefs, data, prefs.getBool(_keyStepsLinked) ?? false);
    Reminders.schedule(data);
    return state;
  }

  void _mutate(AppData Function(AppData) block, {bool reschedule = false}) {
    _data = block(_data);
    _prefs.setString(_keyData, jsonEncode(_data.toJson()));
    notifyListeners();
    if (reschedule) Reminders.schedule(_data);
  }

  void _mutateDay(int epochDay, DayLog Function(DayLog) block) =>
      _mutate((d) => d.copyWith(days: {...d.days, epochDay: block(d.day(epochDay))}));

  void completeOnboarding(Profile profile, MeasurementEntry first) =>
      _mutate((d) => d.copyWith(profile: () => profile, entries: [first]), reschedule: true);

  void updateProfile(Profile profile) => _mutate((d) => d.copyWith(profile: () => profile), reschedule: true);

  void addFood(int epochDay, String label, int kcal) => _mutateDay(
        epochDay,
        (day) => day.copyWith(foods: [
          ...day.foods,
          FoodItem(id: DateTime.now().microsecondsSinceEpoch, label: label.trim(), kcal: kcal),
        ]),
      );

  void removeFood(int epochDay, int id) =>
      _mutateDay(epochDay, (day) => day.copyWith(foods: day.foods.where((f) => f.id != id).toList()));

  void setManualSteps(int epochDay, int? steps) =>
      _mutateDay(epochDay, (day) => day.copyWith(manualSteps: () => steps));

  /// [originalDay] je datum merenja koje se menja (ako je datum promenjen, staro se briše).
  void saveEntry(MeasurementEntry entry, int? originalDay) => _mutate((d) {
        final others = d.entries.where((e) => e.epochDay != entry.epochDay && e.epochDay != originalDay);
        return d.copyWith(entries: [...others, entry]..sort((a, b) => a.epochDay.compareTo(b.epochDay)));
      }, reschedule: true);

  void deleteEntry(int epochDay) => _mutate(
        (d) => d.copyWith(entries: d.entries.where((e) => e.epochDay != epochDay).toList()),
        reschedule: true,
      );

  Future<void> connectSteps(int epochDay) async {
    try {
      if (await steps.requestAccess()) {
        _stepsLinked = true;
        await _prefs.setBool(_keyStepsLinked, true);
        notifyListeners();
        await syncSteps(epochDay);
      }
    } catch (_) {}
  }

  Future<void> syncSteps(int epochDay) async {
    if (!_stepsLinked) return;
    try {
      final count = await steps.stepsFor(epochDay);
      if (count != null && _data.day(epochDay).syncedSteps != count) {
        _mutateDay(epochDay, (day) => day.copyWith(syncedSteps: () => count));
      }
    } catch (_) {}
  }

  Future<void> exportBackup(Rect? origin) async {
    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/bloom-$date.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_data.toJson()));
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      sharePositionOrigin: origin,
    ));
  }

  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
      final picked = result?.files.single;
      if (picked == null) return false;
      final text = picked.bytes != null
          ? utf8.decode(picked.bytes!)
          : await File(picked.path!).readAsString();
      final imported = AppData.fromJson(jsonDecode(text) as Map<String, dynamic>);
      if (imported.profile == null) return false;
      _mutate((_) => imported, reschedule: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  void resetAll() => _mutate((_) => const AppData(), reschedule: true);
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
