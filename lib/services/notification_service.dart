import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static FlutterLocalNotificationsPlugin get plugin => _plugin;

  // Планирует будильник. Если repeatDays пуст — сработает один раз.
  // Если есть дни повтора — создаём отдельное системное уведомление на каждый день.
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    await cancelAlarm(alarm.id);

    const androidDetails = AndroidNotificationDetails(
      'alarm_channel_id',
      'Будильники',
      channelDescription: 'Канал для срабатывания будильников',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (alarm.repeatDays.isEmpty) {
      // Разовый будильник — ближайшее совпадение времени
      final scheduledDate = _nextInstanceOfTime(
        alarm.time.hour,
        alarm.time.minute,
      );

      await _plugin.zonedSchedule(
        _idForOneTime(alarm.id),
        'Пора вставать!',
        alarm.taskType.label,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: alarm.id,
      );
    } else {
      // Повторяющийся будильник — по одному уведомлению на каждый выбранный день недели
      for (final weekday in alarm.repeatDays) {
        final scheduledDate = _nextInstanceOfWeekdayTime(
          weekday,
          alarm.time.hour,
          alarm.time.minute,
        );

       
        await _plugin.zonedSchedule(
          _idForWeekday(alarm.id, weekday),
          'Пора вставать!',
          alarm.taskType.label,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: alarm.id,
        );
      }
    }
  }

  static Future<void> cancelAlarm(String alarmId) async {
    await _plugin.cancel(_idForOneTime(alarmId));
    for (int weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_idForWeekday(alarmId, weekday));
    }
  }

  // Уникальный числовой id для системы уведомлений на основе id будильника
  static int _idForOneTime(String alarmId) => alarmId.hashCode & 0x7FFFFFFF;

  static int _idForWeekday(String alarmId, int weekday) =>
      (alarmId.hashCode ^ (weekday * 1000)) & 0x7FFFFFFF;

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(
    int weekday,
    int hour,
    int minute,
  ) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
