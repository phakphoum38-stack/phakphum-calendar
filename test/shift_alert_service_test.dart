import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/calendar_busy_period.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/models/shift_alert.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';
import 'package:phakphum_calendar/services/shift_alert_service.dart';

void main() {
  const service = ShiftAlertService();

  test('creates an OFF period after a night shift and flags morning duty', () {
    final shifts = service.addOffDutyPeriods([
      _shift('NP1', DateTime(2026, 8, 10), DateTime(2026, 8, 10, 8)),
      _shift('UP1', DateTime(2026, 8, 10, 8), DateTime(2026, 8, 10, 16)),
    ]);

    final off = shifts.singleWhere((shift) => shift.isOffDuty);
    expect(off.start, DateTime(2026, 8, 10, 8));
    expect(off.end, DateTime(2026, 8, 10, 16));
    expect(off.generated, isTrue);

    final alerts = service.build(
      shifts: shifts,
      calendarPeriods: const [],
      decisions: const {},
    );
    expect(
      alerts.map((alert) => alert.type),
      containsAll([ShiftAlertType.offAfterNight, ShiftAlertType.offConflict]),
    );
    expect(alerts.every((alert) => alert.isPending), isTrue);
  });

  test('detects sheet overlap and Google Calendar overlap', () {
    final first = _shift(
      'UP2',
      DateTime(2026, 8, 12, 8),
      DateTime(2026, 8, 12, 16),
    );
    final second = _shift(
      'UG',
      DateTime(2026, 8, 12, 7, 30),
      DateTime(2026, 8, 12, 12),
    );
    final alerts = service.build(
      shifts: [first, second],
      calendarPeriods: [
        CalendarBusyPeriod(
          id: 'external-1',
          title: 'ประชุม',
          start: DateTime(2026, 8, 12, 13),
          end: DateTime(2026, 8, 12, 14),
          legacyKey: 'external',
        ),
      ],
      decisions: const {},
    );

    expect(
      alerts.where((alert) => alert.type == ShiftAlertType.shiftOverlap),
      hasLength(1),
    );
    expect(
      alerts.where((alert) => alert.type == ShiftAlertType.calendarOverlap),
      hasLength(1),
    );
  });

  test('does not flag the same shift already present in Calendar', () {
    final shift = _shift(
      'UP4',
      DateTime(2026, 8, 15, 8),
      DateTime(2026, 8, 15, 16),
    );
    final alerts = service.build(
      shifts: [shift],
      calendarPeriods: [
        CalendarBusyPeriod(
          id: 'same-event',
          title: shift.code,
          start: shift.start,
          end: shift.end,
          legacyKey: CalendarService.legacyKeyFor(shift),
        ),
      ],
      decisions: const {},
    );

    expect(alerts, isEmpty);
  });
}

Shift _shift(String code, DateTime start, DateTime end) => Shift(
  code: code,
  rowLabel: code,
  assignedName: 'ภาคภูมิ',
  start: start,
  end: end,
  sheetTitle: 'สิงหาคม 2569',
  cell: 'A1',
  category: ShiftCategory.own,
);
