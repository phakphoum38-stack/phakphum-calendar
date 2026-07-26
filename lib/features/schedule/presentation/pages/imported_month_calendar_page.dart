import 'package:flutter/material.dart';

import '../../../../domain/entities/schedule.dart';
import '../../../../l10n/l10n.dart';
import '../../../excel_import/domain/shift_record.dart';
import '../../data/imported_schedule_adapter.dart';
import '../../data/schedule_service.dart';
import '../controllers/schedule_controller.dart';
import 'monthly_schedule_page.dart';

/// Displays imported shift records using the canonical monthly schedule UI.
class ImportedMonthCalendarPage extends StatefulWidget {
  const ImportedMonthCalendarPage({
    this.records = const [],
    this.schedule,
    this.controllerFactory,
    super.key,
    this.adapter = const ImportedScheduleAdapter(),
  });

  /// Imported records to display.
  final List<ShiftRecord> records;
  final Schedule? schedule;
  final ScheduleController Function(Schedule)? controllerFactory;

  /// Boundary adapter used to populate the schedule domain.
  final ImportedScheduleAdapter adapter;

  @override
  State<ImportedMonthCalendarPage> createState() =>
      _ImportedMonthCalendarPageState();
}

class _ImportedMonthCalendarPageState extends State<ImportedMonthCalendarPage> {
  late final Schedule canonicalSchedule =
      widget.schedule ?? widget.adapter.createSchedule(widget.records);
  late final ScheduleController controller =
      widget.controllerFactory?.call(canonicalSchedule) ??
      ScheduleController(
        service: ScheduleService(schedule: canonicalSchedule),
        initialMonth:
            canonicalSchedule.months.firstOrNull?.month ??
            widget.adapter.initialMonth(widget.records),
      );

  @override
  void initState() {
    super.initState();
    controller.validateSchedule();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MonthlySchedulePage(
      controller: controller,
      title: context.l10n.monthCalendar,
    );
  }
}
