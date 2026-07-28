import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/features/excel_import/domain/shift_record.dart'
    as imported;
import 'package:phakphum_calendar/features/schedule/data/imported_schedule_adapter.dart';
import 'package:phakphum_calendar/features/schedule/data/legacy_schedule_adapter.dart';
import 'package:phakphum_calendar/features/workflow/application/canonical_schedule_event_mapper.dart';
import 'package:phakphum_calendar/models/shift.dart' as legacy;

void main() {
  test('Excel import records convert to the canonical Schedule aggregate', () {
    const adapter = ImportedScheduleAdapter();
    final schedule = adapter.createSchedule([
      imported.ShiftRecord(
        date: DateTime(2026, 7, 24),
        shift: 'Morning',
        employee: 'Anan',
        department: 'ER',
        location: 'Ward A',
        notes: 'Charge',
        rowNumber: 2,
      ),
      imported.ShiftRecord(
        date: DateTime(2026, 8, 1),
        shift: 'Night',
        employee: 'Mali',
        department: 'ICU',
        rowNumber: 3,
      ),
    ], id: 'import-1');

    expect(schedule, isA<Schedule>());
    expect(schedule.id, 'import-1');
    expect(schedule.months, hasLength(2));
    final assignment = schedule
        .month(DateTime(2026, 7))!
        .day(DateTime(2026, 7, 24))!
        .assignments
        .single;
    expect(assignment.employee.fullName, 'Anan');
    expect(assignment.employee.department.name, 'ER');
    expect(assignment.shift.code, 'Morning');
    expect(assignment.location, 'Ward A');
    expect(assignment.remark, 'Charge');
  });

  test('legacy shifts round-trip through the canonical Schedule', () {
    const adapter = LegacyScheduleAdapter();
    final source = legacy.Shift(
      code: 'NP2',
      rowLabel: 'P2 ดึก',
      assignedName: 'Anan',
      start: DateTime(2026, 7, 24),
      end: DateTime(2026, 7, 24, 8),
      sheetTitle: 'July',
      cell: 'Y7',
      category: legacy.ShiftCategory.borrowedPaid,
      excluded: true,
      generated: true,
      linkedShiftKey: 'linked',
      sourceColorValue: 0xFF00FF00,
      customTitle: 'Custom night',
      calendarColorId: '10',
      relationshipComment: 'สถานะ: รับเวร/คนแทนเวร\nเจ้าของเวรเดิม: Somchai',
    );

    final conversion = adapter.toCanonical([source]);
    final restored = conversion.toLegacyShifts().single;

    expect(conversion.schedule, isA<Schedule>());
    expect(restored.code, source.code);
    expect(restored.rowLabel, source.rowLabel);
    expect(restored.assignedName, source.assignedName);
    expect(restored.start, source.start);
    expect(restored.end, source.end);
    expect(restored.sheetTitle, source.sheetTitle);
    expect(restored.cell, source.cell);
    expect(restored.category, source.category);
    expect(restored.excluded, source.excluded);
    expect(restored.generated, source.generated);
    expect(restored.linkedShiftKey, source.linkedShiftKey);
    expect(restored.sourceColorValue, source.sourceColorValue);
    expect(restored.customTitle, source.customTitle);
    expect(restored.calendarColorId, source.calendarColorId);
    expect(restored.relationshipComment, source.relationshipComment);
    expect(
      conversion.schedule.months.single.days
          .expand((day) => day.assignments)
          .single
          .remark,
      contains('เจ้าของเวรเดิม'),
    );
    expect(
      const CanonicalScheduleEventMapper()
          .map(conversion.schedule)
          .single
          .description,
      contains('เจ้าของเวรเดิม'),
    );
  });
}
