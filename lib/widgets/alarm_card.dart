import 'package:flutter/material.dart';
import '../models/alarm_model.dart';
import '../theme/app_theme.dart';

class AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = alarm.isEnabled;
    final primaryColor = isOn ? AppTheme.textPrimary : AppTheme.textTertiary;
    final iconColor = isOn ? AppTheme.accent : AppTheme.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          splashColor: AppTheme.accent.withOpacity(0.06),
          highlightColor: AppTheme.accent.withOpacity(0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.time.format(context),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(alarm.taskType.icon, size: 13, color: iconColor),
                        const SizedBox(width: 6),
                        Text(
                          '${alarm.taskType.label} · ${alarm.repeatLabel}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.85,
                  child: Switch(value: isOn, onChanged: onToggle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}