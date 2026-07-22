import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/relationship_engine/domain/user_shift_change.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/roster_cell_assignment.dart';
import 'package:phakphum_calendar/features/workflow/application/workflow_preview_builder.dart';

void main() {
  test('builds an add preview for a received shift', () {
    final assignment = RosterCellAssignment(
      spreadsheetId: 'spreadsheet',
      sheetId: 1,
      sheetTitle: 'กรกฎาคม',
      sourceCell: 'B10',
      date: DateTime(2026, 7, 24),
      category: 'ER',
      period: 'เช้า',
      slot: '1',
      workerName: 'ภาคภูมิ',
    );

    final preview = const WorkflowPreviewBuilder().build(
      changes: [
        UserShiftChange(
          type: UserShiftChangeType.received,
          positionKey: 'key',
          after: assignment,
        ),
      ],
      existing: const [],
    );

    expect(preview.simulation.summary.addCount, 1);
    expect(preview.simulation.summary.blockedCount, 0);
    expect(preview.timeMax.isAfter(preview.timeMin), isTrue);
  });
}
