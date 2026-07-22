import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/diff_engine/application/calendar_diff_engine.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  const engine = CalendarDiffEngine();

  test('classifies add, update, delete, and unchanged', () {
    final start = DateTime(2026, 8, 4, 8);
    final end = DateTime(2026, 8, 4, 16);

    final result = engine.compare(
      desired: [
        CalendarEventCandidate(
          syncId: 'add',
          title: 'ER เช้า',
          start: start,
          end: end,
          shouldExist: true,
        ),
        CalendarEventCandidate(
          syncId: 'update',
          title: 'CT-ER บ่าย',
          start: start,
          end: end,
          shouldExist: true,
        ),
        CalendarEventCandidate(
          syncId: 'same',
          title: 'GEN เช้า',
          start: start,
          end: end,
          shouldExist: true,
        ),
      ],
      existing: [
        CalendarEventCandidate(
          syncId: 'update',
          title: 'Old title',
          start: start,
          end: end,
          shouldExist: true,
        ),
        CalendarEventCandidate(
          syncId: 'same',
          title: 'GEN เช้า',
          start: start,
          end: end,
          shouldExist: true,
        ),
        CalendarEventCandidate(
          syncId: 'delete',
          title: 'Removed shift',
          start: start,
          end: end,
          shouldExist: true,
        ),
      ],
    );

    expect(result.toAdd.map((event) => event.syncId), contains('add'));
    expect(result.toUpdate.map((event) => event.syncId), contains('update'));
    expect(result.toDelete.map((event) => event.syncId), contains('delete'));
    expect(result.unchanged.map((event) => event.syncId), contains('same'));
  });

  test('deletes existing event when desired event should not exist', () {
    final start = DateTime(2026, 8, 4, 8);
    final end = DateTime(2026, 8, 4, 16);

    final result = engine.compare(
      desired: [
        CalendarEventCandidate(
          syncId: 'given-away',
          title: 'ER เช้า',
          start: start,
          end: end,
          shouldExist: false,
        ),
      ],
      existing: [
        CalendarEventCandidate(
          syncId: 'given-away',
          title: 'ER เช้า',
          start: start,
          end: end,
          shouldExist: true,
        ),
      ],
    );

    expect(result.toDelete, hasLength(1));
    expect(result.toDelete.single.syncId, 'given-away');
  });
}
