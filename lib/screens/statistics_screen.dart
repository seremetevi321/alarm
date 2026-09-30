import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/sleep_record.dart';
import '../services/sleep_storage_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isWeekView = true;
  List<SleepRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    setState(() {
      _records = SleepStorageService.loadRecords();
    });
  }

  // Группируем по дню (дата пробуждения), берём последнюю запись за день,
  // если их несколько
  Map<DateTime, double> _groupedHoursByDay(int daysBack) {
    final now = DateTime.now();
    final Map<DateTime, double> result = {};

    for (int i = daysBack - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayRecords = _records.where((r) {
        final wokeDay = DateTime(r.wokeAt.year, r.wokeAt.month, r.wokeAt.day);
        return wokeDay == day;
      }).toList();

      if (dayRecords.isNotEmpty) {
        final totalMinutes = dayRecords
            .map((r) => r.duration.inMinutes)
            .reduce((a, b) => a + b);
        result[day] = totalMinutes / dayRecords.length / 60.0;
      } else {
        result[day] = 0;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final daysBack = _isWeekView ? 7 : 30;
    final grouped = _groupedHoursByDay(daysBack);
    final values = grouped.values.toList();
    final nonZeroValues = values.where((v) => v > 0).toList();

    final average = nonZeroValues.isEmpty
        ? 0.0
        : nonZeroValues.reduce((a, b) => a + b) / nonZeroValues.length;
    final hours = average.floor();
    final minutes = ((average - hours) * 60).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Статистика сна')),
      body: _records.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Пока нет данных.\nСтатистика появится после первого будильника, выключенного через задание.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildToggleChip('Неделя', _isWeekView, () {
                        setState(() => _isWeekView = true);
                      }),
                      const SizedBox(width: 8),
                      _buildToggleChip('Месяц', !_isWeekView, () {
                        setState(() => _isWeekView = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Среднее время сна',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nonZeroValues.isEmpty ? '—' : '${hours}ч ${minutes}мин',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 12,
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: _isWeekView,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      final days = grouped.keys.toList();
                                      if (index < 0 || index >= days.length) {
                                        return const SizedBox.shrink();
                                      }
                                      const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                                      final weekday = days[index].weekday;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          names[weekday - 1],
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(values.length, (index) {
                                final maxVal = values.reduce((a, b) => a > b ? a : b);
                                final isMax = values[index] == maxVal && values[index] > 0;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: values[index],
                                      color: isMax
                                          ? AppTheme.accent
                                          : const Color(0xFF33333F),
                                      width: _isWeekView ? 18 : 6,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Всего записей: ${_records.length}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildToggleChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.background : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}