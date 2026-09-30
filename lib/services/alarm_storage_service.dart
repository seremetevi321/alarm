import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_model.dart';

class AlarmStorageService {
  static const String _boxName = 'alarms_box';
  static const String _key = 'alarms_list';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final box = Hive.box(_boxName);
    final jsonList = alarms.map((a) => a.toJson()).toList();
    await box.put(_key, jsonEncode(jsonList));
  }

  static List<AlarmModel> loadAlarms() {
    final box = Hive.box(_boxName);
    final raw = box.get(_key);
    if (raw == null) return [];

    final List decoded = jsonDecode(raw as String);
    return decoded
        .map((item) => AlarmModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}