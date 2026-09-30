import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../theme/app_theme.dart';
import '../services/alarm_service.dart';

class AddEditAlarmScreen extends StatefulWidget {
  final AlarmModel? existingAlarm;

  const AddEditAlarmScreen({super.key, this.existingAlarm});

  @override
  State<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends State<AddEditAlarmScreen> {
  late DateTime _selectedDateTime;
  late Set<int> _selectedDays;
  final TaskType _selectedTask = TaskType.pushUps;
  int _targetReps = 10;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAlarm;
    final now = DateTime.now();

    if (existing != null) {
      _selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        existing.time.hour,
        existing.time.minute,
      );
    } else {
      _selectedDateTime = now;
    }

    _selectedDays = existing != null ? existing.repeatDays.toSet() : {};
    _targetReps = existing?.targetReps ?? 10;
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _saveAlarm() async {
    final alarm = AlarmModel(
      id: widget.existingAlarm?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      time: TimeOfDay(
        hour: _selectedDateTime.hour,
        minute: _selectedDateTime.minute,
      ),
      repeatDays: _selectedDays.toList(),
      taskType: _selectedTask,
      isEnabled: true,
      targetReps: _targetReps,
    );

    await AlarmService.scheduleAlarm(alarm);

    if (mounted) {
      Navigator.pop(context, alarm);
    }
  }

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingAlarm == null ? 'Новый будильник' : 'Изменить будильник'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text(
              'Сохранить',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Колесо выбора времени — как в приложении "Часы" на iOS
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: CupertinoTheme(
                data: const CupertinoThemeData(
                  brightness: Brightness.dark,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: _selectedDateTime,
                  use24hFormat: true,
                  onDateTimeChanged: (newDateTime) {
                    setState(() => _selectedDateTime = newDateTime);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Дни повтора
          const Text(
            'Повтор',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = index + 1;
              final isSelected = _selectedDays.contains(day);
              return GestureDetector(
                onTap: () => _toggleDay(day),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accent : AppTheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        color: isSelected ? AppTheme.background : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Количество отжиманий — степпер
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center_outlined, color: AppTheme.accent),
                const SizedBox(width: 12),
                const Text(
                  'Отжиманий',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _buildStepperButton(
                  icon: Icons.remove,
                  onTap: _targetReps > 1
                      ? () => setState(() => _targetReps--)
                      : null,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_targetReps',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStepperButton(
                  icon: Icons.add,
                  onTap: _targetReps < 50
                      ? () => setState(() => _targetReps++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, VoidCallback? onTap}) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.accent.withOpacity(0.15) : AppTheme.divider,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isEnabled ? AppTheme.accent : AppTheme.textTertiary,
        ),
      ),
    );
  }
}