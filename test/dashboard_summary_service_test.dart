import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/features/dashboard/application/dashboard_summary_service.dart';

import 'support/canonical_schedule_fixture.dart';

void main() {
  test('prepares today, tomorrow, month and next-shift metrics', () {
    final source = canonicalScheduleFixture();
    final firstDay = source.months.first.days.first.date;
    final summary = const DashboardSummaryService().build(
      schedule: source,
      now: firstDay,
      conflictCount: 2,
    );

    expect(summary.todayAssignments, isNotEmpty);
    expect(summary.monthAssignmentCount, greaterThanOrEqualTo(1));
    expect(summary.nextAssignment, isNotNull);
    expect(summary.nextAssignmentDate, firstDay);
    expect(summary.conflictCount, 2);
  });

  test('empty schedule produces a stable zero summary', () {
    final summary = const DashboardSummaryService().build(
      schedule: Schedule(id: 'empty', name: 'Empty'),
      now: DateTime(2026, 7, 27),
      conflictCount: 0,
    );

    expect(summary.todayAssignments, isEmpty);
    expect(summary.tomorrowAssignments, isEmpty);
    expect(summary.monthAssignmentCount, 0);
    expect(summary.nextAssignment, isNull);
  });
}
