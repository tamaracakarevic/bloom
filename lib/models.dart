enum ActivityLevel {
  sedentary(1.2, 'Uglavnom sedim', 'Posao za stolom, bez treninga'),
  light(1.375, 'Lagano aktivna', 'Trening 1–3 puta nedeljno'),
  moderate(1.55, 'Umereno aktivna', 'Trening 3–5 puta nedeljno'),
  high(1.725, 'Veoma aktivna', 'Trening 6–7 puta nedeljno');

  const ActivityLevel(this.factor, this.title, this.subtitle);
  final double factor;
  final String title;
  final String subtitle;
}

enum Pace {
  gentle(250, 'Nežno', 'oko 0,25 kg nedeljno'),
  steady(500, 'Umereno', 'oko 0,5 kg nedeljno'),
  fast(750, 'Brže', 'oko 0,75 kg nedeljno');

  const Pace(this.deficit, this.title, this.subtitle);
  final int deficit;
  final String title;
  final String subtitle;
}

enum Measure {
  chest('chest', 'Grudi', 'Preko najisturenijeg dela grudi'),
  underbust('underbust', 'Ispod grudi', 'Tamo gde ide korpa grudnjaka'),
  waist('waist', 'Struk', 'Najuži deo, malo iznad pupka'),
  belly('belly', 'Stomak', 'Preko pupka, opušteno'),
  hipsHigh('hips_high', 'Kukovi', 'U visini koščica kuka'),
  hips('hips', 'Bokovi', 'Najširi deo, preko zadnjice');

  const Measure(this.key, this.title, this.hint);
  final String key;
  final String title;
  final String hint;
}

T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((e) => e.name == name, orElse: () => fallback);

class Profile {
  const Profile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.startWeightKg,
    required this.goalWeightKg,
    required this.activity,
    required this.pace,
    required this.manualTargetKcal,
    required this.startEpochDay,
    this.reminderEnabled = true,
  });

  final String name;
  final int age;
  final double heightCm;
  final double startWeightKg;
  final double? goalWeightKg;
  final ActivityLevel activity;
  final Pace pace;
  final int? manualTargetKcal;
  final int startEpochDay;
  final bool reminderEnabled;

  Profile copyWith({
    String? name,
    int? age,
    double? heightCm,
    double? Function()? goalWeightKg,
    ActivityLevel? activity,
    Pace? pace,
    int? Function()? manualTargetKcal,
    bool? reminderEnabled,
  }) =>
      Profile(
        name: name ?? this.name,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        startWeightKg: startWeightKg,
        goalWeightKg: goalWeightKg != null ? goalWeightKg() : this.goalWeightKg,
        activity: activity ?? this.activity,
        pace: pace ?? this.pace,
        manualTargetKcal: manualTargetKcal != null
            ? manualTargetKcal()
            : this.manualTargetKcal,
        startEpochDay: startEpochDay,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'heightCm': heightCm,
        'startWeightKg': startWeightKg,
        'goalWeightKg': goalWeightKg,
        'activity': activity.name,
        'pace': pace.name,
        'manualTargetKcal': manualTargetKcal,
        'startEpochDay': startEpochDay,
        'reminderEnabled': reminderEnabled,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        name: j['name'] as String? ?? '',
        age: (j['age'] as num).toInt(),
        heightCm: (j['heightCm'] as num).toDouble(),
        startWeightKg: (j['startWeightKg'] as num).toDouble(),
        goalWeightKg: (j['goalWeightKg'] as num?)?.toDouble(),
        activity: _enumOr(ActivityLevel.values, j['activity'] as String?,
            ActivityLevel.light),
        pace: _enumOr(Pace.values, j['pace'] as String?, Pace.steady),
        manualTargetKcal: (j['manualTargetKcal'] as num?)?.toInt(),
        startEpochDay: (j['startEpochDay'] as num).toInt(),
        reminderEnabled: j['reminderEnabled'] as bool? ?? true,
      );
}

class MeasurementEntry {
  const MeasurementEntry({
    required this.epochDay,
    required this.weightKg,
    required this.values,
    this.note = '',
  });

  final int epochDay;
  final double weightKg;
  final Map<String, double> values;
  final String note;

  double? value(Measure m) => values[m.key];

  Map<String, dynamic> toJson() => {
        'day': epochDay,
        'weight': weightKg,
        'values': values,
        'note': note,
      };

  factory MeasurementEntry.fromJson(Map<String, dynamic> j) => MeasurementEntry(
        epochDay: (j['day'] as num).toInt(),
        weightKg: (j['weight'] as num).toDouble(),
        values: ((j['values'] as Map?) ?? {})
            .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        note: j['note'] as String? ?? '',
      );
}

class FoodItem {
  const FoodItem({required this.id, required this.label, required this.kcal});

  final int id;
  final String label;
  final int kcal;

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'kcal': kcal};

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        id: (j['id'] as num).toInt(),
        label: j['label'] as String? ?? '',
        kcal: (j['kcal'] as num).toInt(),
      );
}

class DayLog {
  const DayLog({
    required this.epochDay,
    this.foods = const [],
    this.manualSteps,
    this.syncedSteps,
  });

  final int epochDay;
  final List<FoodItem> foods;
  final int? manualSteps;
  final int? syncedSteps;

  int get eaten => foods.fold(0, (sum, f) => sum + f.kcal);
  int get steps => manualSteps ?? syncedSteps ?? 0;

  DayLog copyWith({
    List<FoodItem>? foods,
    int? Function()? manualSteps,
    int? Function()? syncedSteps,
  }) =>
      DayLog(
        epochDay: epochDay,
        foods: foods ?? this.foods,
        manualSteps: manualSteps != null ? manualSteps() : this.manualSteps,
        syncedSteps: syncedSteps != null ? syncedSteps() : this.syncedSteps,
      );

  Map<String, dynamic> toJson() => {
        'day': epochDay,
        'foods': foods.map((f) => f.toJson()).toList(),
        'manualSteps': manualSteps,
        'syncedSteps': syncedSteps,
      };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        epochDay: (j['day'] as num).toInt(),
        foods: ((j['foods'] as List?) ?? [])
            .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
            .toList(),
        manualSteps: (j['manualSteps'] as num?)?.toInt(),
        syncedSteps: (j['syncedSteps'] as num?)?.toInt(),
      );
}

class AppData {
  const AppData({this.profile, this.entries = const [], this.days = const {}});

  final Profile? profile;

  /// Uvek sortirano od najstarijeg ka najnovijem.
  final List<MeasurementEntry> entries;
  final Map<int, DayLog> days;

  MeasurementEntry? get latest => entries.isEmpty ? null : entries.last;
  double? get currentWeight => latest?.weightKg ?? profile?.startWeightKg;
  DayLog day(int epochDay) => days[epochDay] ?? DayLog(epochDay: epochDay);

  AppData copyWith({
    Profile? Function()? profile,
    List<MeasurementEntry>? entries,
    Map<int, DayLog>? days,
  }) =>
      AppData(
        profile: profile != null ? profile() : this.profile,
        entries: entries ?? this.entries,
        days: days ?? this.days,
      );

  Map<String, dynamic> toJson() => {
        'version': 1,
        'profile': profile?.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'days': (days.values.toList()
              ..sort((a, b) => a.epochDay.compareTo(b.epochDay)))
            .map((d) => d.toJson())
            .toList(),
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final entries = ((j['entries'] as List?) ?? [])
        .map((e) => MeasurementEntry.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.epochDay.compareTo(b.epochDay));
    final days = ((j['days'] as List?) ?? [])
        .map((d) => DayLog.fromJson(d as Map<String, dynamic>));
    return AppData(
      profile: j['profile'] == null
          ? null
          : Profile.fromJson(j['profile'] as Map<String, dynamic>),
      entries: entries,
      days: {for (final d in days) d.epochDay: d},
    );
  }
}

final _epoch = DateTime.utc(1970);

int epochDayOf(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).difference(_epoch).inDays;

/// Lokalni datum (ponoć) za dati dan.
DateTime dateOf(int epochDay) {
  final u = _epoch.add(Duration(days: epochDay));
  return DateTime(u.year, u.month, u.day);
}

int today() => epochDayOf(DateTime.now());
