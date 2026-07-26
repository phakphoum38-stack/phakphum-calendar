import 'package:flutter/material.dart';

import '../../domain/schedule_day.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/schedule_controller_host.dart';
import '../widgets/schedule_grid.dart';
import '../widgets/schedule_view_scaffold.dart';
import '../widgets/schedule_view_selector.dart';

class ScheduleWorkspacePage extends StatefulWidget {
  const ScheduleWorkspacePage({super.key, this.controller});

  final ScheduleController? controller;

  @override
  State<ScheduleWorkspacePage> createState() => _ScheduleWorkspacePageState();
}

class _ScheduleWorkspacePageState extends State<ScheduleWorkspacePage> {
  ScheduleViewMode mode = ScheduleViewMode.month;

  @override
  Widget build(BuildContext context) {
    return ScheduleControllerHost(
      controller: widget.controller,
      builder: (context, controller) => ScheduleViewScaffold(
        title: 'Schedule',
        controller: controller,
        viewSelector: ScheduleViewSelector(
          value: mode,
          onChanged: (value) => setState(() => mode = value),
        ),
        child: ScheduleGrid(
          days: _days(controller),
          assignmentsFor: controller.assignmentsFor,
          showMonthPadding: mode == ScheduleViewMode.month,
          selectedDate: controller.selectedDay,
          onDaySelected: (day) {
            controller.selectDay(day.date);
            if (mode != ScheduleViewMode.day) {
              setState(() => mode = ScheduleViewMode.day);
            }
          },
        ),
      ),
    );
  }

  List<ScheduleDay> _days(ScheduleController controller) {
    if (mode == ScheduleViewMode.month) {
      return controller.schedule.days;
    }

    final anchor =
        controller.selectedDay ??
        controller.selectedDate ??
        _todayInMonth(controller) ??
        controller.schedule.days.first.date;
    if (mode == ScheduleViewMode.day) {
      final day = controller.schedule.day(anchor);
      return day == null ? const [] : [day];
    }

    final start = anchor.subtract(Duration(days: anchor.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return controller.schedule.days
        .where((day) => !day.date.isBefore(start) && !day.date.isAfter(end))
        .toList(growable: false);
  }

  DateTime? _todayInMonth(ScheduleController controller) {
    final today = DateTime.now();
    return today.year == controller.currentMonth.year &&
            today.month == controller.currentMonth.month
        ? today
        : null;
  }
}
