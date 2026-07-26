import 'package:flutter/material.dart';

class CalendarSyncProgressCard extends StatelessWidget {
  const CalendarSyncProgressCard({
    super.key,
    required this.progress,
    required this.percent,
    required this.message,
  });

  final double progress;
  final int percent;
  final String message;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0).toDouble();

    return Card(
      key: const Key('calendarSyncProgressCard'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.sync),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'กำลังประมวลผล',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$percent%',
                  key: const Key('calendarSyncProgressPercent'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              key: const Key('calendarSyncProgressIndicator'),
              value: safeProgress,
            ),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'กำลังเตรียมข้อมูล...' : message,
              key: const Key('calendarSyncProgressMessage'),
            ),
          ],
        ),
      ),
    );
  }
}
