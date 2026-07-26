import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/schedule_day.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/employee_chip.dart';
import '../widgets/schedule_controller_host.dart';
import '../widgets/schedule_view_scaffold.dart';
import '../widgets/shift_chip.dart';

class DailySchedulePage extends StatelessWidget {
  const DailySchedulePage({super.key, this.controller});

  final ScheduleController? controller;

  @override
  Widget build(BuildContext context) {
    return ScheduleControllerHost(
      controller: controller,
      builder: (context, controller) {
        final day = _selectedDay(controller);
        return ScheduleViewScaffold(
          title: 'Daily Schedule',
          controller: controller,
          child: day == null
              ? const Center(child: Text('Select a date to view assignments.'))
              : _DailyAssignments(day: day, controller: controller),
        );
      },
    );
  }

  ScheduleDay? _selectedDay(ScheduleController controller) {
    final selected = controller.selectedDay ?? controller.selectedDate;
    if (selected != null) {
      return controller.schedule.day(selected);
    }
    final now = DateTime.now();
    return controller.schedule.day(now) ?? controller.schedule.days.first;
  }
}

class _DailyAssignments extends StatelessWidget {
  const _DailyAssignments({required this.day, required this.controller});

  final ScheduleDay day;
  final ScheduleController controller;

  @override
  Widget build(BuildContext context) {
    final assignments = controller.assignmentsFor(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat.yMMMMEEEEd().format(day.date),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (assignments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  controller.hasActiveFilters
                      ? 'No assignments match the active filters '
                            'for this date.'
                      : 'No assignments for this date.',
                ),
              ),
            ),
          )
        else
          for (final assignment in assignments)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    EmployeeChip(employee: assignment.employee),
                    ShiftChip(shift: assignment.shift),
                    if (assignment.remark case final remark?) Text(remark),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
