import 'dart:io';

import 'package:health/health.dart';

import '../models.dart';

/// Koraci iz Apple Zdravlja (iPhone) ili Health Connect-a (Android).
class StepsService {
  bool get available => true;

  final _health = Health();
  bool _configured = false;

  Future<void> _ensure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// iOS nikad ne javlja da li je čitanje odbijeno — tada samo stižu nule.
  Future<bool> requestAccess() async {
    await _ensure();
    if (Platform.isAndroid) {
      final status = await _health.getHealthConnectSdkStatus();
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        await _health.installHealthConnect();
        return false;
      }
    }
    return _health.requestAuthorization(
      [HealthDataType.STEPS],
      permissions: [HealthDataAccess.READ],
    );
  }

  Future<int?> stepsFor(int epochDay) async {
    await _ensure();
    return _health.getTotalStepsInInterval(
        dateOf(epochDay), dateOf(epochDay + 1));
  }
}
