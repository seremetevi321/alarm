import 'dart:async';
import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../theme/app_theme.dart';
import '../widgets/alarm_card.dart';
import '../services/alarm_service.dart';
import '../services/alarm_storage_service.dart';
import '../services/sleep_storage_service.dart';
import 'add_edit_alarm_screen.dart';


class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  List<AlarmModel> _alarms = [];
  DateTime? _activeSleepStart;
  Timer? _persistDebounce;

  @override
  void initState() {
    super.initState();
    _loadAlarms();
    _loadSleepSession();
  }

  @override
  void dispose() {
    _persistDebounce?.cancel();
    super.dispose();
  }

  void _loadAlarms() {
    setState(() {
      _alarms = AlarmStorageService.loadAlarms();
    });
  }

  void _loadSleepSession() {
    setState(() {
      _activeSleepStart = SleepStorageService.getActiveSessionStart();
    });
  }

  void _persist() {
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), () {
      AlarmStorageService.saveAlarms(_alarms);
    });
  }

  void _startSleep() async {
    await SleepStorageService.startSleepSession();
    _loadSleepSession();
  }

  void _cancelSleep() async {
    await SleepStorageService.cancelSleepSession();
    _loadSleepSession();
  }

  void _openAddScreen() async {
    final newAlarm = await Navigator.push<AlarmModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAlarmScreen()),
    );
    if (newAlarm != null) {
      setState(() => _alarms.add(newAlarm));
      _persist();
    }
  }

  void _deleteAlarm(int index) {
    final removed = _alarms[index];
    AlarmService.cancelAlarm(removed.id);
    setState(() => _alarms.removeAt(index));
    _persist();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Будильник удалён'),
        backgroundColor: AppTheme.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Отменить',
          textColor: AppTheme.accent,
          onPressed: () {
            setState(() => _alarms.insert(index, removed));
            if (removed.isEnabled) {
              AlarmService.scheduleAlarm(removed);
            }
            _persist();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Будильники'),

),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: _buildSleepButton(),
          ),
          Expanded(
            child: _alarms.isEmpty
                ? Center(
                    child: Text(
                      'Пока нет будильников\nНажмите +, чтобы добавить',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textTertiary, height: 1.5),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = _alarms[index];
                      return Dismissible(
                        key: ValueKey(alarm.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteAlarm(index),
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.only(right: 22),
                          alignment: Alignment.centerRight,
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                        ),
                        child: AlarmCard(
                          alarm: alarm,
                          onToggle: (value) async {
                            final updated = alarm.copyWith(isEnabled: value);
                            if (value) {
                              await AlarmService.scheduleAlarm(updated);
                            } else {
                              await AlarmService.cancelAlarm(alarm.id);
                            }
                            setState(() => _alarms[index] = updated);
                            _persist();
                          },
                          onTap: () {
                            // редактирование добавим позже
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSleepButton() {
    if (_activeSleepStart != null) {
      final timeText =
          '${_activeSleepStart!.hour.toString().padLeft(2, '0')}:${_activeSleepStart!.minute.toString().padLeft(2, '0')}';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.accentMuted.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.bedtime, color: AppTheme.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Вы легли спать в $timeText',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
              ),
            ),
            GestureDetector(
              onTap: _cancelSleep,
              child: const Text(
                'Отменить',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _startSleep,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        splashColor: AppTheme.accent.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bedtime_outlined, color: AppTheme.accent, size: 18),
              SizedBox(width: 8),
              Text(
                'Ложусь спать',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}