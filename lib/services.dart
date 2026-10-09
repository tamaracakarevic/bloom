export 'platform/steps.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';

/// Lokalno obaveštenje 7 dana posle poslednjeg merenja, u 10h.
class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const intervalDays = 7;

  /// Web (iPhone početni ekran) ne podržava zakazana obaveštenja.
  static bool get supported => !kIsWeb;

  static Future<void> init() async {
    if (!supported) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(
          tz.getLocation(await FlutterTimezone.getLocalTimezone()));
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
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
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
