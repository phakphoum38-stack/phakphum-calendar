import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/relationship_engine/domain/user_shift_change.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/roster_cell_assignment.dart';
import 'package:phakphum_calendar/features/workflow/application/user_shift_event_mapper.dart';

RosterCellAssignment assignment({
  required String cell,
  required String worker,
}) => RosterCellAssignment(
      spreadsheetId: 'spreadsheet',
      sheetId: 1,
      sheetTitle: 'กรกฎาคม',
      sourceCell: cell,
      date: DateTime(2026, 7, 24),
      category: 'ER',
      period: 'เช้า',
      slot: '1',
      workerName: worker,
    );

void main() {
  const mapper = UserShiftEventMapper();

  test('received shift becomes an event that should exist', () {
    final result = mapper.mapChanges([
      UserShiftChange(
        type: UserShiftChangeType.received,
        positionKey: 'key',
        before: assignment(cell: 'B10', worker: 'สมชาย'),
        after: assignment(cell: 'B10', worker: 'ภาคภูมิ'),
      ),
    ]);

    expect(result.blockedCount, 0);
    expect(result.candidates.single.shouldExist, isTrue);
    expect(result.candidates.single.title, contains('ER เช้า'));
  });

  test('given-away shift becomes a deletion candidate', () {
    final result = mapper.mapChanges([
      UserShiftChange(
        type: UserShiftChangeType.givenAway,
        positionKey: 'key',
        before: assignment(cell: 'B10', worker: 'ภาคภูมิ'),
        after: assignment(cell: 'B10', worker: 'สมชาย'),
      ),
    ]);

    expect(result.candidates.single.shouldExist, isFalse);
  });

  test('unknown shift time blocks synchronization', () {
    final unknown = RosterCellAssignment(
      spreadsheetId: 'spreadsheet',
      sheetId: 1,
      sheetTitle: 'กรกฎาคม',
      sourceCell: 'C10',
      date: DateTime(2026, 7, 24),
      category: 'CT',
      period: 'เช้า',
      slot: '1',
      workerName: 'ภาคภูมิ',
    );

    final result = mapper.mapChanges([
      UserShiftChange(
        type: UserShiftChangeType.received,
        positionKey: 'key',
        after: unknown,
      ),
    ]);

    expect(result.blockedCount, 1);
    expect(result.candidates, isEmpty);
  });
}
