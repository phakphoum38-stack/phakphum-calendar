import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/services/shift_alert_service.dart';

void main() {
  const service = ShiftAlertService();

  test(
    'creates only OFF after the last real night shift across a roster cutoff',
    () {
      final night = Shift(
        code: 'N',
        rowLabel: 'เวรดึก',
        assignedName: 'ผู้ใช้งาน',
        start: DateTime(2026, 9, 15),
        end: DateTime(2026, 9, 15, 8),
        sheetTitle: '16 ส.ค. 69 - 15 ก.ย. 69',
        cell: 'AF2',
        category: ShiftCategory.own,
      );

      final result = service.addOffDutyPeriods([night]);
      final generated = result.where((shift) => shift.generated).toList();

      expect(result.where((shift) => !shift.generated), [night]);
      expect(generated, hasLength(1));
      expect(generated.single.isOffDuty, isTrue);
      expect(generated.single.start, DateTime(2026, 9, 16, 8));
      expect(generated.single.end, DateTime(2026, 9, 16, 16));
      expect(generated.single.linkedShiftKey, night.sourceKey);
    },
  );

  test('does not invent any ordinary shifts after the roster cutoff', () {
    final dayShift = Shift(
      code: 'M',
      rowLabel: 'เวรเช้า',
      assignedName: 'ผู้ใช้งาน',
      start: DateTime(2026, 9, 15, 8),
      end: DateTime(2026, 9, 15, 16),
      sheetTitle: '16 ส.ค. 69 - 15 ก.ย. 69',
      cell: 'AF3',
      category: ShiftCategory.own,
    );

    final result = service.addOffDutyPeriods([dayShift]);

    expect(result, [dayShift]);
    expect(result.where((shift) => shift.generated), isEmpty);
  });
}
