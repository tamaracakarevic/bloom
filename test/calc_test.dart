import 'package:bloom/calc.dart';
import 'package:bloom/format.dart';
import 'package:bloom/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = Profile(
    name: 'T',
    age: 30,
    heightCm: 165,
    startWeightKg: 70,
    goalWeightKg: 62,
    activity: ActivityLevel.light,
    pace: Pace.steady,
    manualTargetKcal: null,
    startEpochDay: 0,
  );

  test('BMR koristi Mifflin-St Jeor formulu za žene', () {
    // 700 + 1031.25 - 150 - 161
    expect(Calc.bmr(70, 165, 30), closeTo(1420.25, 0.001));
  });

  test('preporuka = održavanje − deficit, zaokruženo na 10', () {
    // 1420.25 * 1.375 = 1952.8 -> 1953 - 500 = 1453 -> 1450
    expect(Calc.maintenance(profile, 70), 1953);
    expect(Calc.suggestedTarget(profile, 70), 1450);
  });

  test('preporuka nikad ispod 1200', () {
    final tiny = Profile.fromJson({
      ...profile.toJson(),
      'age': 70,
      'heightCm': 150,
      'activity': 'sedentary',
      'pace': 'fast',
    });
    expect(Calc.suggestedTarget(tiny, 45), Calc.minKcal);
  });

  test('preporuka ne ide ispod BMR-a kad je tempo preoštar', () {
    final fast = profile.copyWith(pace: Pace.fast);
    // 1953 - 750 = 1203 < BMR 1420 -> podiže se na 1420
    expect(Calc.paceCapped(fast, 70), isTrue);
    expect(Calc.suggestedTarget(fast, 70), 1420);
    expect(Calc.paceCapped(profile, 70), isFalse);
  });

  test('ručni cilj ima prednost', () {
    expect(
        Calc.target(profile.copyWith(manualTargetKcal: () => 1600), 70), 1600);
  });

  test('koraci povećavaju budžet i potrošnju', () {
    const day = DayLog(
        epochDay: 1,
        foods: [FoodItem(id: 1, label: 'a', kcal: 1000)],
        manualSteps: 10000);
    final s = Calc.summarize(profile, 70, day);
    expect(s.stepsKcal, 350);
    expect(s.budget, 1450 + 350);
    expect(s.deficit, 1953 + 350 - 1000);
    expect(s.remaining, 800);
  });

  test('ručni koraci imaju prednost nad automatskim', () {
    expect(
        const DayLog(epochDay: 1, manualSteps: 5000, syncedSteps: 9000).steps,
        5000);
    expect(const DayLog(epochDay: 1, syncedSteps: 9000).steps, 9000);
  });

  test('JSON rezervna kopija se vraća bez gubitka', () {
    final data = AppData(
      profile: profile,
      entries: const [
        MeasurementEntry(
            epochDay: 5, weightKg: 69.5, values: {'waist': 78}, note: 'x')
      ],
      days: {
        5: const DayLog(
            epochDay: 5,
            foods: [FoodItem(id: 1, label: 'Ručak', kcal: 650)],
            syncedSteps: 8000)
      },
    );
    final back = AppData.fromJson(data.toJson());
    expect(back.toJson(), data.toJson());
  });

  test('epochDay i datum su usklađeni', () {
    final d = DateTime(2026, 10, 9, 23, 30);
    expect(dateOf(epochDayOf(d)), DateTime(2026, 10, 9));
  });

  test('formatiranje na srpskom', () {
    expect(fmtI(1510), '1.510');
    expect(fmtD(72.5), '72,5');
    expect(weeksText(1, accusative: true), '1 nedelju');
    expect(weeksText(3), '3 nedelje');
    expect(weeksText(21), '21 nedelja');
    expect(weeksText(12), '12 nedelja');
  });
}
