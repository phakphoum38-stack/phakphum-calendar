import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/roster_reference_comparison.dart';
import 'package:phakphum_calendar/models/shift.dart';

void main() {
  test('classifies exact, changed, missing and sync-only shifts', () {
    final exact = _shift(code: 'A', day: 1);
    final changedReference = _shift(code: 'B', day: 2);
    final changedSync = changedReference.copyWith(
      end: changedReference.end.add(const Duration(hours: 1)),
    );
    final comparison = RosterReferenceComparison.compare(
      syncShifts: [
        exact,
        changedSync,
        _shift(code: 'SYNC', day: 3),
        Shift(
          code: 'OFF',
          rowLabel: 'OFF',
          assignedName: 'Tester',
          start: DateTime(2026, 8, 4, 8),
          end: DateTime(2026, 8, 4, 16),
          sheetTitle: 'generated',
          cell: '',
          category: ShiftCategory.off,
          generated: true,
        ),
      ],
      referenceShifts: [
        exact,
        changedReference,
        _shift(code: 'SOURCE', day: 5),
      ],
    );

    expect(comparison.matched, 1);
    expect(comparison.changed, 1);
    expect(comparison.missingFromSync, 1);
    expect(comparison.onlyInSync, 1);
    expect(comparison.issueCount, 3);
    expect(comparison.isExactMatch, isFalse);
  });
}

Shift _shift({required String code, required int day}) => Shift(
  code: code,
  rowLabel: '$code shift',
  assignedName: 'Tester',
  start: DateTime(2026, 8, day, 8),
  end: DateTime(2026, 8, day, 16),
  sheetTitle: 'August',
  cell: 'A$day',
  category: ShiftCategory.own,
);
