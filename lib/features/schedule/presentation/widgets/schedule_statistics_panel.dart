import 'package:flutter/material.dart';

import '../../domain/schedule_statistics.dart';

class ScheduleStatisticsPanel extends StatelessWidget {
  const ScheduleStatisticsPanel({required this.statistics, super.key});

  final ScheduleStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Statistic(label: 'Total shifts', value: '${statistics.totalShifts}'),
        _Statistic(label: 'Night shifts', value: '${statistics.nightShifts}'),
        _Statistic(
          label: 'Holiday shifts',
          value: '${statistics.holidayShifts}',
        ),
        _Statistic(
          label: 'Working hours',
          value: _formatHours(statistics.workingHours),
        ),
      ],
    );
  }

  String _formatHours(double value) =>
      value == value.roundToDouble() ? '${value.toInt()} h' : '$value h';
}

class _Statistic extends StatelessWidget {
  const _Statistic({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
