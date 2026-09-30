import 'package:alarm/alarm.dart';
import '../models/alarm_model.dart';

class AlarmService {
  static const String defaultSound = 'assets/sounds/alarm_sound.mp3';

  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    await cancelAlarm(alarm.id);

    if (alarm.repeatDays.isEmpty) {
      final dateTime = _nextInstanceOfTime(alarm.time.hour, alarm.time.minute);
      await _setSingleAlarm(alarm, dateTime, idForOneTime(alarm.id));
    } else {
      for (final weekday in alarm.repeatDays) {
        final dateTime = _nextInstanceOfWeekdayTime(
          weekday,
          alarm.time.hour,
          alarm.time.minute,
        );
        await _setSingleAlarm(alarm, dateTime, idForWeekday(alarm.id, weekday));
      }
    }
  }

  static Future<void> _setSingleAlarm(
    AlarmModel alarm,
    DateTime dateTime,
    int id,
  ) async {
    final settings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: defaultSound,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fixed(
        volume: 1.0,
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Пора вставать!',
        body: alarm.taskType.label,
      ),
    );
    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelAlarm(String alarmId) async {
    await Alarm.stop(idForOneTime(alarmId));
    for (int weekday = 1; weekday <= 7; weekday++) {
      await Alarm.stop(idForWeekday(alarmId, weekday));
    }
  }

  static Future<void> lowerVolume(int alarmId, {double factor = 0.5}) async {
    final current = await Alarm.getAlarm(alarmId);
    if (current == null) return;

    final currentVolume = current.volumeSettings.volume ?? 1.0;

    await Alarm.set(
      alarmSettings: current.copyWith(
        dateTime: DateTime.now(),
        volumeSettings: VolumeSettings.fixed(
          volume: currentVolume * factor,
          volumeEnforced: true,
        ),
      ),
    );
  }

  static int idForOneTime(String alarmId) => alarmId.hashCode & 0x7FFFFFFF;

  static int idForWeekday(String alarmId, int weekday) =>
      (alarmId.hashCode ^ (weekday * 1000)) & 0x7FFFFFFF;

  static AlarmModel? findAlarmModelForSettingsId(
    int settingsId,
    List<AlarmModel> alarms,
  ) {
    for (final alarm in alarms) {
      if (idForOneTime(alarm.id) == settingsId) return alarm;
      for (int weekday = 1; weekday <= 7; weekday++) {
        if (idForWeekday(alarm.id, weekday) == settingsId) return alarm;
      }
    }
    return null;
  }

  static DateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static DateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}