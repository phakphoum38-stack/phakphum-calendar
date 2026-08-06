import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';

void main() {
  test('calendar description includes received-shift relationship', () {
    final shift = Shift(
      code: 'P2',
      rowLabel: 'P2 ดึก',
      assignedName: 'Phakphum',
      start: DateTime(2026, 9, 4),
      end: DateTime(2026, 9, 4, 8),
      sheetTitle: 'ก.ย. 2569',
      cell: 'E12',
      category: ShiftCategory.own,
      relationshipComment:
          'สถานะ: รับเวร/คนแทนเวร\n'
          'เจ้าของเวรเดิม: Somchai\n'
          'ผู้ปฏิบัติงานปัจจุบัน: Phakphum',
    );

    final description = CalendarService.descriptionFor(shift);

    expect(description, contains('สถานะ: รับเวร/คนแทนเวร'));
    expect(description, contains('เจ้าของเวรเดิม: Somchai'));
    expect(description, contains('ผู้ปฏิบัติงานปัจจุบัน: Phakphum'));
  });

  test('calendar description omits an empty relationship block', () {
    final shift = Shift(
      code: 'P1',
      rowLabel: 'P1 เช้า',
      assignedName: 'Phakphum',
      start: DateTime(2026, 9, 5, 8),
      end: DateTime(2026, 9, 5, 16),
      sheetTitle: 'ก.ย. 2569',
      cell: 'F8',
      category: ShiftCategory.own,
    );

    final description = CalendarService.descriptionFor(shift);

    expect(description, isNot(contains('สถานะ:')));
    expect(description, contains('ประเภท: เวรของตัวเอง'));
  });

  test('same time with a different shift title is not treated as existing', () {
    final p2 = Shift(
      code: 'AP2',
      rowLabel: 'P2 บ่าย',
      assignedName: 'ภาคภูมิ',
      start: DateTime(2026, 8, 8, 16),
      end: DateTime(2026, 8, 9),
      sheetTitle: '16 กค69-15 สค.69',
      cell: 'Y10',
      category: ShiftCategory.own,
    );
    final ctEr = Shift(
      code: 'ACTER',
      rowLabel: 'CT ER บ่าย',
      assignedName: 'ภาคภูมิ',
      start: DateTime(2026, 8, 8, 16),
      end: DateTime(2026, 8, 9),
      sheetTitle: '16 กค69-15 สค.69',
      cell: 'Y25',
      category: ShiftCategory.own,
    );

    final existingKeys = <String>{CalendarService.managedTimeKeyFor(p2)};

    expect(CalendarService.matchesExisting(p2, existingKeys), isTrue);
    expect(CalendarService.matchesExisting(ctEr, existingKeys), isFalse);
  });
}
