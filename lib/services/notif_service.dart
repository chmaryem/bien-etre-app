import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ---------- SINGLETON POUR LA NOTIF ----------
final FlutterLocalNotificationsPlugin _notif =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'habitudes_channel_v2',
  'Rappels d’habitudes (v2)',
  description: 'Notifications quotidiennes pour les habitudes',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

// ---------- CALLBACKS TOP-LEVEL (OBLIGATOIRE) ----------

/// Affiche une notification simple (utilisée par les callbacks d’alarmes)
@pragma('vm:entry-point')
Future<void> _alarmShowSimple(int id, String title, String body) async {
  // Initialisation “à froid” (process bg)
  const androidInit = AndroidInitializationSettings('@drawable/ic_stat_habit');
  const iosInit = DarwinInitializationSettings();
  const initSettings =
  InitializationSettings(android: androidInit, iOS: iosInit);
  await _notif.initialize(initSettings);

  final android = _notif.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(_channel);

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      icon: '@drawable/ic_stat_habit',
      category: AndroidNotificationCategory.reminder,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      playSound: true,
      ticker: 'Rappel',
    ),
    iOS: const DarwinNotificationDetails(),
  );

  await _notif.show(id, title, body, details);
}

/// ✅ Entrée correct pour oneShot/oneShotAt avec params Map (TEST +15s)
@pragma('vm:entry-point')
Future<void> _alarmSimpleEntry(int id, Map<String, dynamic> data) async {
  final int nid = (data['id'] as int?) ?? id;
  final String title = (data['title'] as String?) ?? 'Rappel';
  final String body = (data['body'] as String?) ?? '';
  await _alarmShowSimple(nid, title, body);
}

/// Entrée + réarmement quotidien (déjà OK)
@pragma('vm:entry-point')
Future<void> _alarmDailyRearm(
    int id,
    String title,
    String body,
    String hhmm,
    ) async {
  await _alarmShowSimple(id, title, body);

  // Reprogramme pour demain à la même heure
  final now = DateTime.now();
  final parts = hhmm.split(':');
  final h = int.tryParse(parts[0]) ?? 8;
  final m = int.tryParse(parts[1]) ?? 0;
  var next =
  DateTime(now.year, now.month, now.day, h, m).add(const Duration(days: 1));

  await AndroidAlarmManager.oneShotAt(
    next,
    id, // on garde le même id
    _alarmDailyEntry,
    exact: true,
    wakeup: true,
    rescheduleOnReboot: true,
    allowWhileIdle: true,
    params: {'id': id, 'title': title, 'body': body, 'hhmm': hhmm},
  );
}

@pragma('vm:entry-point')
Future<void> _alarmDailyEntry(int id, Map<String, dynamic> data) async {
  final int nid = data['id'] as int;
  final String title = data['title'] as String;
  final String body = data['body'] as String;
  final String hhmm = data['hhmm'] as String;
  await _alarmDailyRearm(nid, title, body, hhmm);
}

// ---------- SERVICE ----------
class NotificationService {
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@drawable/ic_stat_habit');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
    InitializationSettings(android: androidInit, iOS: iosInit);

    await _notif.initialize(initSettings);

    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);

    _inited = true;
  }

  Future<void> requestNotificationsPermission() async {
    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    await _notif
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await android?.areNotificationsEnabled();
    return enabled ?? true;
  }

  // --- Compatibilité avec home_screen.dart (menu debug) ---
  Future<bool> canScheduleExact() async {
    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  Future<bool> requestExactAlarmsPermission() async {
    final android = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  // ---- Tests UI existants ----
  Future<void> showNowTest() async {
    if (!_inited) await init();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        icon: '@drawable/ic_stat_habit',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _notif.show(
      9999,
      'Test notification · now 🔔',
      'Si tu vois ceci, la notification fonctionne',
      details,
    );
  }

  Future<void> showIn5sViaTimer() async {
    if (!_inited) await init();
    await Future<void>.delayed(const Duration(seconds: 5));
    await showNowTest();
  }

  // ---- Programmation via ANDROID ALARM MANAGER ----

  /// ✅ Test “+15s” via AlarmManager (exact, wakeup) — corrige la signature
  Future<void> scheduleInSeconds(int seconds) async {
    if (!_inited) await init();
    final when = DateTime.now().add(Duration(seconds: seconds));

    // ignore: avoid_print
    print('[AlarmMgr] oneShotAt +${seconds}s → $when');

    await AndroidAlarmManager.oneShotAt(
      when,
      9998, // id unique pour le test
      _alarmSimpleEntry, // <-- callback correct (int, Map)
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
      params: {
        'id': 9998,
        'title': 'Test planifié · +${seconds}s ⏱️',
        'body': 'Si tu vois ceci, AlarmManager a réveillé l’app.',
      },
    );
  }

  Future<void> scheduleIn1Minute() => scheduleInSeconds(60);

  /// Notification quotidienne à [hhmm] via AlarmManager (se réarme chaque jour).
  Future<void> scheduleDailySmart({
    required int idUnique,
    required String titre,
    required String corps,
    required String hhmm,
  }) async {
    if (!_inited) await init();
    final parts = hhmm.split(':');
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;

    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, h, m);
    if (!first.isAfter(now)) first = first.add(const Duration(days: 1));

    // ignore: avoid_print
    print('[AlarmMgr] daily first → $first (hhmm=$hhmm) id=$idUnique');

    await AndroidAlarmManager.oneShotAt(
      first,
      idUnique,
      _alarmDailyEntry,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
      params: {'id': idUnique, 'title': titre, 'body': corps, 'hhmm': hhmm},
    );
  }

  Future<List<PendingNotificationRequest>> pending() async {
    if (!_inited) await init();
    return _notif.pendingNotificationRequests();
  }

  Future<void> cancelForHabit(int idUnique) async {
    // Annule la notif (si planifiée) ET l’alarme système
    await _notif.cancel(idUnique);
    await AndroidAlarmManager.cancel(idUnique);
  }
}
