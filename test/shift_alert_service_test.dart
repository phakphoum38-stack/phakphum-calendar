import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/calendar_busy_period.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/models/shift_alert.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';
import 'package:phakphum_calendar/services/shift_alert_service.dart';

void main() {
  const service = ShiftAlertService();

  test('creates OFF 08:00-16:00 after every night shift', () {
    final shifts = service.addOffDutyPeriods([
      _shift('NP1', DateTime(2026, 8, 10), DateTime(2026, 8, 10, 8)),
      _shift('NP2', DateTime(2026, 8, 11), DateTime(2026, 8, 11, 8)),
    ]);

    final offShifts = shifts.where((shift) => shift.isOffDuty).toList();
    expect(offShifts, hasLength(2));
    expect(offShifts[0].start, DateTime(2026, 8, 10, 8));
    expect(offShifts[0].end, DateTime(2026, 8, 10, 16));
    expect(offShifts[1].start, DateTime(2026, 8, 11, 8));
    expect(offShifts[1].end, DateTime(2026, 8, 11, 16));
    expect(offShifts.every((shift) => shift.generated), isTrue);
  });

  test('flags a roster duty that overlaps OFF after a night shift', () {
    final shifts = service.addOffDutyPeriods([
      _shift('NP1', DateTime(2026, 8, 10), DateTime(2026, 8, 10, 8)),
      _shift('UP1', DateTime(2026, 8, 10, 8), DateTime(2026, 8, 10, 16)),
    ]);

    final alerts = service.build(
      shifts: shifts,
      calendarPeriods: const [],
      decisions: const {},
    );

    expect(
      alerts.where((alert) => alert.type == ShiftAlertType.offAfterNight),
      hasLength(1),
    );
    expect(
      alerts.where((alert) => alert.type == ShiftAlertType.offConflict),
      hasLength(1),
    );
    expect(alerts.where((alert) => alert.isPending), hasLength(1));
  });

  test('warns when a Calendar event overlaps OFF 08:00-16:00', () {
    final shifts = service.addOffDutyPeriods([
      _shift('NER', DateTime(2026, 8, 12), DateTime(2026, 8, 12, 8)),
    ]);

    final alerts = service.build(
      shifts: shifts,
      calendarPeriods: [
        CalendarBusyPeriod(
          id: 'external-off-conflict',
          title: 'กิจกรรมทดสอบ',
          start: DateTime(2026, 8, 12, 9),
          end: DateTime(2026, 8, 12, 10),
          legacyKey: 'external',
        ),
      ],
      decisions: const {},
    );

    final conflict = alerts.singleWhere(
      (alert) => alert.type == ShiftAlertType.calendarOverlap,
    );
    expect(conflict.title, contains('OFF 08:00–16:00'));
    expect(conflict.start, DateTime(2026, 8, 12, 9));
    expect(conflict.end, DateTime(2026, 8, 12, 10));
    expect(conflict.isPending, isTrue);
  });

  test('detects roster overlap and a busy Calendar overlap', () {
    final first = _shift(
      'UP2',
      DateTime(2026, 8, 14, 8),
      DateTime(2026, 8, 14, 16),
    );
    final second = _shift(
      'UG',
      DateTime(2026, 8, 14, 7, 30),
      DateTime(2026, 8, 14, 12),
    );

    final alerts = service.build(
      shifts: [first, second],
      calendarPeriods: [
        CalendarBusyPeriod(
          id: 'external-1',
          title: 'ประชุมทดสอบ',
          start: DateTime(2026, 8, 14, 13),
          end: DateTime(2026, 8, 14, 14),
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

  test('does not warn for the same shift already created by the app', () {
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
  assignedName: 'ผู้ใช้งานทดสอบ',
  start: start,
  end: end,
  sheetTitle: 'ชีตทดสอบ',
  cell: 'A1',
  category: ShiftCategory.own,
);
