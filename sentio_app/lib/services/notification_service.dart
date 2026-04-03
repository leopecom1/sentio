import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs
  static const _morningId = 100;
  static const _eveningId = 101;
  static const _streakDangerId = 102;
  static const _weeklySummaryId = 103;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }

    return true;
  }

  // ── Morning reminder ──

  Future<void> scheduleMorningReminder(TimeOfDay time, String userName) async {
    await _plugin.cancel(_morningId);

    final messages = [
      'Buenos días, $userName. ¿Cómo arrancás hoy?',
      'Un nuevo día, $userName. ¿Cómo te sentís?',
      '$userName, tomá un minuto para registrar cómo estás.',
    ];
    final msg = messages[DateTime.now().day % messages.length];

    await _scheduleDaily(
      id: _morningId,
      title: 'Sentio',
      body: msg,
      hour: time.hour,
      minute: time.minute,
    );
  }

  // ── Evening reminder ──

  Future<void> scheduleEveningReminder(TimeOfDay time, String userName) async {
    await _plugin.cancel(_eveningId);

    final messages = [
      '¿Cómo estuvo hoy, $userName? Un check-in rápido antes de cerrar el día.',
      '$userName, antes de descansar: ¿cómo te sentís?',
      'Fin del día, $userName. ¿Querés registrar cómo fue?',
    ];
    final msg = messages[DateTime.now().day % messages.length];

    await _scheduleDaily(
      id: _eveningId,
      title: 'Sentio',
      body: msg,
      hour: time.hour,
      minute: time.minute,
    );
  }

  // ── Streak danger alert ──

  Future<void> scheduleStreakDangerAlert(int streak) async {
    await _plugin.cancel(_streakDangerId);
    if (streak < 3) return; // Only alert if streak is worth protecting

    await _scheduleDaily(
      id: _streakDangerId,
      title: 'Tu racha está en peligro',
      body: 'Tu racha de $streak días está en peligro! Un check-in rápido la mantiene viva.',
      hour: 20,
      minute: 0,
    );
  }

  // ── Weekly summary ──

  Future<void> scheduleWeeklySummary() async {
    await _plugin.cancel(_weeklySummaryId);

    // Schedule for Sunday at 21:00
    final now = tz.TZDateTime.now(tz.local);
    var nextSunday = now.add(Duration(days: (DateTime.sunday - now.weekday) % 7));
    nextSunday = tz.TZDateTime(
      tz.local,
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      21,
      0,
    );
    if (nextSunday.isBefore(now)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      _weeklySummaryId,
      'Resumen semanal',
      '¿Cómo fue tu semana? Revisá tus insights en Sentio.',
      nextSunday,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Cancel helpers ──

  Future<void> cancelMorning() => _plugin.cancel(_morningId);
  Future<void> cancelEvening() => _plugin.cancel(_eveningId);
  Future<void> cancelStreakDanger() => _plugin.cancel(_streakDangerId);
  Future<void> cancelWeeklySummary() => _plugin.cancel(_weeklySummaryId);
  Future<void> cancelAll() => _plugin.cancelAll();

  // Cancel today's streak danger (called after check-in)
  Future<void> cancelTodayStreakDanger() => _plugin.cancel(_streakDangerId);

  // ── Private helpers ──

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'sentio_reminders',
        'Recordatorios',
        channelDescription: 'Recordatorios de check-in y bienestar',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
