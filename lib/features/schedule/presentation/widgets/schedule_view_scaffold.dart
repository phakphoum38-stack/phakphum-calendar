import 'package:flutter/material.dart';

import '../controllers/schedule_controller.dart';
import 'legend.dart';
import 'month_header.dart';
import 'schedule_filters.dart';
import 'schedule_statistics_panel.dart';

class ScheduleViewScaffold extends StatelessWidget {
  const ScheduleViewScaffold({
    required this.title,
    required this.controller,
    required this.child,
    super.key,
    this.viewSelector,
  });

  final String title;
  final ScheduleController controller;
  final Widget child;
  final Widget? viewSelector;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          MonthHeader(
            month: controller.currentMonth,
            onPrevious: controller.previousMonth,
            onNext: controller.nextMonth,
          ),
          if (viewSelector != null) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.center, child: viewSelector!),
          ],
          const SizedBox(height: 20),
          ScheduleFilters(controller: controller),
          const SizedBox(height: 20),
          ScheduleStatisticsPanel(statistics: controller.statistics),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 20),
          Legend(shifts: controller.shifts),
        ],
      ),
    );
  }
}
