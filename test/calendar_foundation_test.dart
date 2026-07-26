import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/excel_import/domain/shift_record.dart';
import 'package:phakphum_calendar/features/schedule/data/imported_schedule_adapter.dart';
import 'package:phakphum_calendar/features/schedule/presentation/controllers/schedule_controller.dart';
import 'package:phakphum_calendar/features/schedule/presentation/pages/daily_schedule_page.dart';
import 'package:phakphum_calendar/features/schedule/presentation/pages/imported_month_calendar_page.dart';

void main() {
  const adapter = ImportedScheduleAdapter();

  test('generates the complete month containing imported records', () {
    final records = [_record(date: DateTime(2026, 7, 24))];
    final controller = ScheduleController(
      service: adapter.createService(records),
      initialMonth: adapter.initialMonth(records),
    );
    addTearDown(controller.dispose);

    expect(controller.currentMonth, DateTime(2026, 7));
    expect(controller.schedule.days, hasLength(31));
    expect(controller.schedule.days.first.date, DateTime(2026, 7, 1));
    expect(controller.schedule.days.last.date, DateTime(2026, 7, 31));
  });

  test('navigates to previous and next calendar months', () {
    final controller = ScheduleController(initialMonth: DateTime(2026, 1));
    addTearDown(controller.dispose);

    controller.previousMonth();
    expect(controller.currentMonth, DateTime(2025, 12));

    controller.nextMonth();
    controller.nextMonth();
    expect(controller.currentMonth, DateTime(2026, 2));
  });

  test('groups imported shifts into their matching schedule dates', () {
    final records = [
      _record(date: DateTime(2026, 7, 24), employee: 'Anan'),
      _record(date: DateTime(2026, 7, 24), employee: 'Mali', shift: 'Night'),
      _record(date: DateTime(2026, 7, 25), employee: 'Nida'),
    ];
    final service = adapter.createService(records);

    final schedule = service.createSchedule(DateTime(2026, 7));

    expect(schedule.day(DateTime(2026, 7, 24))!.assignments, hasLength(2));
    expect(schedule.day(DateTime(2026, 7, 25))!.assignments, hasLength(1));
    expect(schedule.day(DateTime(2026, 7, 26))!.assignments, isEmpty);
  });

  testWidgets('shows an empty state while retaining the month calendar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ImportedMonthCalendarPage(records: [])),
    );

    expect(find.text('Month Calendar'), findsOneWidget);
    expect(find.text('No shifts scheduled for this month.'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('selecting a multi-shift day shows every assigned staff member', (
    tester,
  ) async {
    final records = [
      _record(date: DateTime(2026, 7, 24), employee: 'Anan'),
      _record(date: DateTime(2026, 7, 24), employee: 'Mali', shift: 'Night'),
    ];
    await tester.pumpWidget(
      MaterialApp(home: ImportedMonthCalendarPage(records: records)),
    );

    final selectedDay = find.text('24').first;
    await tester.ensureVisible(selectedDay);
    await tester.pumpAndSettle();
    await tester.tap(selectedDay);
    await tester.pumpAndSettle();

    expect(find.byType(DailySchedulePage), findsOneWidget);
    expect(find.text('Anan'), findsOneWidget);
    expect(find.text('Mali'), findsOneWidget);
    expect(find.text('Morning'), findsWidgets);
    expect(find.text('Night'), findsWidgets);
  });
}

ShiftRecord _record({
  required DateTime date,
  String employee = 'Anan',
  String shift = 'Morning',
}) {
  return ShiftRecord(
    date: date,
    shift: shift,
    employee: employee,
    department: 'ER',
    rowNumber: 2,
  );
}
