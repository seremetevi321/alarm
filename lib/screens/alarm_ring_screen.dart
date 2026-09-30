import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/alarm_model.dart';
import '../widgets/push_up_counter.dart';
import '../services/sleep_storage_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;
  final TaskType taskType;
  final int targetReps;

  const AlarmRingScreen({
    super.key,
    required this.alarmSettings,
    this.taskType = TaskType.pushUps,
    this.targetReps = 10,
  });

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  bool _cameraStarted = false;

  // Экстренная остановка — доступна только первые 20 секунд после звонка
  static const Duration _emergencyWindow = Duration(seconds: 20);
  static const Duration _holdDuration = Duration(seconds: 7);
  bool _emergencyAvailable = true;
  Timer? _emergencyWindowTimer;

  double _holdProgress = 0.0;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _emergencyWindowTimer = Timer(_emergencyWindow, () {
      if (mounted) setState(() => _emergencyAvailable = false);
    });
  }

  @override
  void dispose() {
    _emergencyWindowTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _completeTask() async {
  await SleepStorageService.recordWakeUp();
  await Alarm.stop(widget.alarmSettings.id);
  if (mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

  void _startHold() {
    const tickMs = 50;
    int elapsed = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      elapsed += tickMs;
      setState(() => _holdProgress = elapsed / _holdDuration.inMilliseconds);
      if (elapsed >= _holdDuration.inMilliseconds) {
        timer.cancel();
        _showEmergencyConfirmation();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() => _holdProgress = 0.0);
  }

  void _showEmergencyConfirmation() {
    setState(() => _holdProgress = 0.0);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Отключить будильник?', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
          'Это будет засчитано как пропущенное задание, а не как выполненное.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // закрыть сам диалог
              await Alarm.stop(widget.alarmSettings.id);
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
  child: const Text('Отключить', style: TextStyle(color: AppTheme.danger)),
),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Пора вставать!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: widget.taskType == TaskType.pushUps
                      ? (_cameraStarted
                          ? PushUpCounter(
                              alarmId: widget.alarmSettings.id,
                              targetReps: widget.targetReps,
                              onCompleted: _completeTask,
                            )
                          : _buildStartScreen())
                      : Center(
                          child: ElevatedButton(
                            onPressed: _completeTask,
                            child: const Text('Выполнено, выключить'),
                          ),
                        ),
                ),
                if (_emergencyAvailable) _buildEmergencyButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onLongPressStart: (_) => _startHold(),
        onLongPressEnd: (_) => _cancelHold(),
        onLongPressCancel: _cancelHold,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppTheme.surface,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_holdProgress > 0)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _holdProgress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(AppTheme.danger.withOpacity(0.3)),
                    ),
                  ),
                ),
              Text(
                'Случайное срабатывание? Удерживайте 7 сек',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fitness_center, color: AppTheme.accent, size: 64),
          const SizedBox(height: 24),
          Text(
            'Сделайте ${widget.targetReps} отжиманий,\nчтобы выключить будильник',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: AppTheme.background,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => setState(() => _cameraStarted = true),
            icon: const Icon(Icons.videocam),
            label: const Text(
              'Включить камеру',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}