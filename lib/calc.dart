import 'dart:math';

import 'models.dart';

class Calc {
  static const kcalPerKg = 7700.0;
  static const minKcal = 1200;

  /// Mifflin-St Jeor, formula za žene.
  static double bmr(double weightKg, double heightCm, int age) =>
      10 * weightKg + 6.25 * heightCm - 5 * age - 161;

  /// Potrošnja bez šetnje — korake dodajemo posebno.
  static int maintenance(Profile p, double weightKg) =>
      (bmr(weightKg, p.heightCm, p.age) * p.activity.factor).round();

  static int suggestedTarget(Profile p, double weightKg) =>
      max(minKcal, _roundTo10(maintenance(p, weightKg) - p.pace.deficit));

  static int target(Profile p, double weightKg) => p.manualTargetKcal ?? suggestedTarget(p, weightKg);

  /// ~0,5 kcal po kg telesne mase na 1000 koraka.
  static int stepsKcal(int steps, double weightKg) => (steps * weightKg * 0.0005).round();

  static double bmi(double weightKg, double heightCm) {
    final m = heightCm / 100;
    return weightKg / (m * m);
  }

  static String bmiLabel(double bmi) {
    if (bmi < 18.5) return 'ispod normale';
    if (bmi < 25) return 'normalna težina';
    if (bmi < 30) return 'povišena težina';
    return 'gojaznost';
  }

  static double waistToHip(double waist, double hips) => waist / hips;

  static String waistToHipLabel(double ratio) {
    if (ratio < 0.80) return 'nizak rizik';
    if (ratio <= 0.85) return 'umeren rizik';
    return 'povišen rizik';
  }

  /// Okvirno nedelja do cilja ako se držiš ciljnih kalorija (bez koraka).
  static double? weeksToGoal(Profile p, double weightKg) {
    final goal = p.goalWeightKg;
    if (goal == null) return null;
    if (weightKg <= goal) return 0;
    final dailyDeficit = maintenance(p, weightKg) - target(p, weightKg);
    if (dailyDeficit <= 0) return null;
    return (weightKg - goal) * kcalPerKg / dailyDeficit / 7;
  }

  static DaySummary summarize(Profile p, double weightKg, DayLog day) {
    final target = Calc.target(p, weightKg);
    final stepsKcal = Calc.stepsKcal(day.steps, weightKg);
    final burned = maintenance(p, weightKg) + stepsKcal;
    return DaySummary(
      target: target,
      eaten: day.eaten,
      stepsKcal: stepsKcal,
      burned: burned,
      hasFood: day.foods.isNotEmpty,
    );
  }

  static int _roundTo10(int v) => ((v + 5) ~/ 10) * 10;
}

class DaySummary {
  const DaySummary({
    required this.target,
    required this.eaten,
    required this.stepsKcal,
    required this.burned,
    required this.hasFood,
  });

  final int target;
  final int eaten;
  final int stepsKcal;
  final int burned;
  final bool hasFood;

  /// Cilj + kalorije zarađene koracima.
  int get budget => target + stepsKcal;
  int get remaining => budget - eaten;
  int get deficit => burned - eaten;
}
