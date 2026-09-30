import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sleep_record.dart';

class SleepStorageService {
  static const String _boxName = 'sleep_box';
  static const String _recordsKey = 'sleep_records';
  static const String _activeStartKey = 'active_sleep_start';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  // Вызывается по нажатию кнопки "Ложусь спать"
  static Future<void> startSleepSession() async {
    final box = Hive.box(_boxName);
    await box.put(_activeStartKey, DateTime.now().toIso8601String());
  }

  static DateTime? getActiveSessionStart() {
    final box = Hive.box(_boxName);
    final raw = box.get(_activeStartKey);
    if (raw == null) return null;
    return DateTime.parse(raw as String);
  }

  static Future<void> cancelSleepSession() async {
    final box = Hive.box(_boxName);
    await box.delete(_activeStartKey);
  }

  // Вызывается при успешном выполнении задания будильника
  static Future<void> recordWakeUp() async {
    final start = getActiveSessionStart();
    if (start == null) return; // не было начатой сессии — нечего фиксировать

    final wokeAt = DateTime.now();

    // Игнорируем аномально короткие сессии (например, случайный тест)
    if (wokeAt.difference(start) < const Duration(minutes: 15)) {
      final box = Hive.box(_boxName);
      await box.delete(_activeStartKey);
      return;
    }

    final records = loadRecords();
    records.add(SleepRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      setAt: start,
      wokeAt: wokeAt,
    ));
    await _saveRecords(records);

    final box = Hive.box(_boxName);
    await box.delete(_activeStartKey);
  }

  static List<SleepRecord> loadRecords() {
    final box = Hive.box(_boxName);
    final raw = box.get(_recordsKey);
    if (raw == null) return [];
    final List decoded = jsonDecode(raw as String);
    return decoded
        .map((item) => SleepRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> _saveRecords(List<SleepRecord> records) async {
    final box = Hive.box(_boxName);
    final jsonList = records.map((r) => r.toJson()).toList();
    await box.put(_recordsKey, jsonEncode(jsonList));
  }
}