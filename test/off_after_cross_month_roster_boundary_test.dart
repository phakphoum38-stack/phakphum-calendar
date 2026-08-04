import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/services/shift_alert_service.dart';

void main() {
  const service = ShiftAlertService();

  final cutoffCases = <({DateTime cutoff, DateTime expectedOff})>[
    (
      cutoff: DateTime(2026, 9, 14),
      expectedOff: DateTime(2026, 9, 15, 8),
    ),
    (
      cutoff: DateTime(2026, 9, 20),
      expectedOff: DateTime(2026, 9, 21, 8),
    ),
    (
      cutoff: DateTime(2026, 9, 30),
      expectedOff: DateTime(2026, 10, 1, 8),
    ),
    (
      cutoff: DateTime(2026, 10, 31),
      expectedOff: DateTime(2026, 11, 1, 8),
    ),
    (
      cutoff: DateTime(2026, 12, 31),
      expectedOff: DateTime(2027, 1, 1, 8),
    ),
  ];

  for (final testCase in cutoffCases) {
    test(
      'creates one linked OFF after night-shift cutoff '
      '${testCase.cutoff.toIso8601String()}',
      () {
        final night = Shift(
          code: 'N',
          rowLabel: 'เวรดึก',
          assignedName: 'ผู้ใช้งาน',
          start: testCase.cutoff,
          end: testCase.cutoff.add(const Duration(hours: 8)),
          sheetTitle: 'ตารางเวรที่มีวันตัดรอบเปลี่ยนได้',
          cell: 'A1',
          category: ShiftCategory.own,
        );

        final result = service.addOffDutyPeriods([night]);
        final generated = result.where((shift) => shift.generated).toList();

        expect(result.where((shift) => !shift.generated), [night]);
        expect(generated, hasLength(1));
        expect(generated.single.isOffDuty, isTrue);
        expect(generated.single.start, testCase.expectedOff);
        expect(
          generated.single.end,
          testCase.expectedOff.add(const Duration(hours: 8)),
        );
        expect(generated.single.linkedShiftKey, night.sourceKey);
      },
    );
  }

  test('does not invent any ordinary shift after a non-night cutoff', () {
    final dayShift = Shift(
      code: 'M',
      rowLabel: 'เวรเช้า',
      assignedName: 'ผู้ใช้งาน',
      start: DateTime(2026, 9, 20, 8),
      end: DateTime(2026, 9, 20, 16),
      sheetTitle: 'ตารางเวรที่มีวันตัดรอบเปลี่ยนได้',
      cell: 'A1',
      category: ShiftCategory.own,
    );

    final result = service.addOffDutyPeriods([dayShift]);

    expect(result, [dayShift]);
    expect(result.where((shift) => shift.generated), isEmpty);
  });
}
