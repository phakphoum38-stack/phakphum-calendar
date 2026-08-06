import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/roster_assignment_timeline.dart';
import 'package:phakphum_calendar/models/shift.dart';

void main() {
  test('keeps change-then-change-back worker order', () {
    final timeline = buildRosterAssignmentTimelines([
      _revision('1', DateTime(2026, 8, 1, 9), 'A'),
      _revision('2', DateTime(2026, 8, 1, 10), 'B'),
      _revision('3', DateTime(2026, 8, 1, 11), 'A'),
    ]).values.single;

    expect(timeline.workerChain, ['A', 'B', 'A']);
  });

  test('keeps onward transfer A to B to C', () {
    final timeline = buildRosterAssignmentTimelines([
      _revision('1', DateTime(2026, 8, 1, 9), 'A'),
      _revision('2', DateTime(2026, 8, 1, 10), 'B'),
      _revision('3', DateTime(2026, 8, 1, 11), 'C'),
    ]).values.single;

    expect(timeline.workerChain, ['A', 'B', 'C']);
  });

  test('deduplicates unrelated revisions with the same worker', () {
    final timeline = buildRosterAssignmentTimelines([
      _revision('1', DateTime(2026, 8, 1, 9), 'A'),
      _revision('2', DateTime(2026, 8, 1, 10), ' A '),
      _revision('3', DateTime(2026, 8, 1, 11), 'B'),
      _revision('4', DateTime(2026, 8, 1, 12), 'B'),
    ]).values.single;

    expect(timeline.workerChain, ['A', 'B']);
    expect(timeline.versions.map((version) => version.revisionId), ['1', '3']);
  });

  test('does not emit a timeline when ownership never changed', () {
    final timelines = buildRosterAssignmentTimelines([
      _revision('1', DateTime(2026, 8, 1, 9), 'A'),
      _revision('2', DateTime(2026, 8, 1, 10), 'A'),
    ]);

    expect(timelines, isEmpty);
  });
}

RosterRevisionShifts _revision(String id, DateTime time, String worker) {
  return RosterRevisionShifts(
    revisionId: id,
    modifiedAt: time,
    shifts: [
      Shift(
        code: 'UP3',
        rowLabel: 'P3 เช้า',
        assignedName: worker,
        start: DateTime(2026, 8, 18, 8),
        end: DateTime(2026, 8, 18, 16),
        sheetTitle: '16 สค - 15 กย 69',
        cell: 'D11',
        category: ShiftCategory.own,
      ),
    ],
  );
}
