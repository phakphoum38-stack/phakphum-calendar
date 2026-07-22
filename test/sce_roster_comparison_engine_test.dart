import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/relationship_engine/application/roster_comparison_engine.dart';
import 'package:phakphum_calendar/features/relationship_engine/application/user_shift_change_classifier.dart';
import 'package:phakphum_calendar/features/relationship_engine/domain/user_shift_change.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/roster_cell_assignment.dart';

RosterCellAssignment assignment(String worker) => RosterCellAssignment(
  spreadsheetId: 'sheet',
  sheetId: 1,
  sheetTitle: 'July',
  sourceCell: 'B10',
  date: DateTime(2026, 7, 16),
  category: 'Portable',
  period: 'บ่าย',
  slot: 'P2',
  workerName: worker,
);

void main() {
  test('detects a received shift for ภาคภูมิ', () {
    const comparison = RosterComparisonEngine();
    final changes = comparison.compare(
      original: [assignment('สมชาย')],
      current: [assignment('ภาคภูมิ')],
    );
    final userChanges = const UserShiftChangeClassifier().classify(
      changes: changes,
      userAliases: const ['ภาคภูมิ'],
    );
    expect(userChanges.single.type, UserShiftChangeType.received);
  });

  test('detects a given-away shift for ภาคภูมิ', () {
    const comparison = RosterComparisonEngine();
    final changes = comparison.compare(
      original: [assignment('ภาคภูมิ')],
      current: [assignment('สมหญิง')],
    );
    final userChanges = const UserShiftChangeClassifier().classify(
      changes: changes,
      userAliases: const ['ภาคภูมิ'],
    );
    expect(userChanges.single.type, UserShiftChangeType.givenAway);
  });
}
