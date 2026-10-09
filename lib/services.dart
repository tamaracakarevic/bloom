import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:health/health.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Koraci iz Apple Zdravlja (iPhone) ili Health Connect-a (Android).
class StepsService {
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
    return _health.getTotalStepsInInterval(dateOf(epochDay), dateOf(epochDay + 1));
  }
}

/// Lokalno obaveštenje 7 dana posle poslednjeg merenja, u 10h.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const intervalDays = 7;

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
      await _plugin.initialize(const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ));
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static Future<void> requestPermission() async {
    if (!_ready) return;
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> schedule(AppData data) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(1);
      final p = data.profile;
      if (p == null || !p.reminderEnabled) return;
      final last = data.latest?.epochDay ?? p.startEpochDay;
      final now = tz.TZDateTime.now(tz.local);
      final due = dateOf(last + intervalDays);
      var when = tz.TZDateTime(tz.local, due.year, due.month, due.day, 10);
      if (!when.isAfter(now)) {
        final t = now.add(const Duration(days: 1));
        when = tz.TZDateTime(tz.local, t.year, t.month, t.day, 10);
      }
      await _plugin.zonedSchedule(
        1,
        'Vreme je za merenje 🌸',
        'Prošlo je 7 dana — upiši kilažu i mere i vidi koliko si napredovala.',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails('measure', 'Nedeljno merenje'),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // podsetnik nije kritičan
    }
  }
}
