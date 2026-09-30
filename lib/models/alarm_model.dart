import 'package:flutter/material.dart';

enum TaskType { none, makeBed, pushUps }

extension TaskTypeExtension on TaskType {
  String get label {
    switch (this) {
      case TaskType.makeBed:
        return 'Заправить кровать';
      case TaskType.pushUps:
        return '10 отжиманий';
      case TaskType.none:
        return 'Без задания';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.makeBed:
        return Icons.camera_alt_outlined;
      case TaskType.pushUps:
        return Icons.fitness_center_outlined;
      case TaskType.none:
        return Icons.notifications_none;
    }
  }
}

class AlarmModel {
  final String id;
  final TimeOfDay time;
  final List<int> repeatDays; // 1 = понедельник ... 7 = воскресенье
  final TaskType taskType;
  final bool isEnabled;
  final String label;
  final int targetReps;

  AlarmModel({
    required this.id,
    required this.time,
    required this.repeatDays,
    required this.taskType,
    required this.isEnabled,
    this.label = '',
    this.targetReps = 10,
  });

  AlarmModel copyWith({
    TimeOfDay? time,
    List<int>? repeatDays,
    TaskType? taskType,
    bool? isEnabled,
    String? label,
    int? targetReps,
  }) {
    return AlarmModel(
      id: id,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      taskType: taskType ?? this.taskType,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      targetReps: targetReps ?? this.targetReps,
    );
  }

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'Один раз';
    if (repeatDays.length == 7) return 'Ежедневно';
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final sorted = [...repeatDays]..sort();
    return sorted.map((d) => names[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': time.hour,
      'minute': time.minute,
      'repeatDays': repeatDays,
      'taskType': taskType.index,
      'isEnabled': isEnabled,
      'label': label,
      'targetReps': targetReps,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
      repeatDays: List<int>.from(json['repeatDays'] as List),
      taskType: TaskType.values[json['taskType'] as int],
      isEnabled: json['isEnabled'] as bool,
      label: json['label'] as String? ?? '',
      targetReps: json['targetReps'] as int? ?? 10,
    );
  }
}