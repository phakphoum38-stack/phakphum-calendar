import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/diff_engine/application/calendar_diff_engine.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  const engine = CalendarDiffEngine();

  CalendarEventCandidate event({
    required String syncId,
    String title = 'Morning shift',
    int day = 27,
    int startHour = 8,
    int endHour = 16,
    bool shouldExist = true,
    String? description,
  }) {
    return CalendarEventCandidate(
      syncId: syncId,
      title: title,
      start: DateTime(2026, 7, day, startHour),
      end: DateTime(2026, 7, day, endHour),
      shouldExist: shouldExist,
      description: description,
    );
  }

  group('CalendarDiffEngine', () {
    test('adds a desired event that does not exist', () {
      final desired = event(syncId: 'shift-1');

      final result = engine.compare(desired: [desired], existing: const []);

      expect(result.toAdd, [desired]);
      expect(result.toUpdate, isEmpty);
      expect(result.toDelete, isEmpty);
      expect(result.unchanged, isEmpty);
      expect(result.hasChanges, isTrue);
    });

    test('updates an event when its content changed', () {
      final oldEvent = event(syncId: 'shift-1', title: 'Old title');

      final newEvent = event(syncId: 'shift-1', title: 'New title');

      final result = engine.compare(desired: [newEvent], existing: [oldEvent]);

      expect(result.toAdd, isEmpty);
      expect(result.toUpdate, [newEvent]);
      expect(result.toDelete, isEmpty);
      expect(result.unchanged, isEmpty);
    });

    test('keeps an identical event unchanged', () {
      final desired = event(syncId: 'shift-1');

      final existing = event(syncId: 'shift-1');

      final result = engine.compare(desired: [desired], existing: [existing]);

      expect(result.toAdd, isEmpty);
      expect(result.toUpdate, isEmpty);
      expect(result.toDelete, isEmpty);
      expect(result.unchanged, [desired]);
      expect(result.hasChanges, isFalse);
    });

    test('deletes an existing event missing from desired events', () {
      final existing = event(syncId: 'shift-1');

      final result = engine.compare(desired: const [], existing: [existing]);

      expect(result.toDelete, [existing]);
      expect(result.hasChanges, isTrue);
    });

    test('deletes an event explicitly marked shouldExist false', () {
      final desired = event(syncId: 'shift-1', shouldExist: false);

      final existing = event(syncId: 'shift-1');

      final result = engine.compare(desired: [desired], existing: [existing]);

      expect(result.toDelete, [existing]);
      expect(result.toAdd, isEmpty);
      expect(result.toUpdate, isEmpty);
      expect(result.unchanged, isEmpty);
    });

    test('does not delete anything when a disabled event never existed', () {
      final desired = event(syncId: 'shift-1', shouldExist: false);

      final result = engine.compare(desired: [desired], existing: const []);

      expect(result.toAdd, isEmpty);
      expect(result.toUpdate, isEmpty);
      expect(result.toDelete, isEmpty);
      expect(result.unchanged, isEmpty);
      expect(result.hasChanges, isFalse);
    });

    test('detects description changes', () {
      final existing = event(syncId: 'shift-1', description: 'CT');

      final desired = event(syncId: 'shift-1', description: 'CT-IPD');

      final result = engine.compare(desired: [desired], existing: [existing]);

      expect(result.toUpdate, [desired]);
    });

    test('sorts results by start date and Sync ID', () {
      final later = event(syncId: 'shift-c', day: 28);

      final earlierB = event(syncId: 'shift-b', day: 27);

      final earlierA = event(syncId: 'shift-a', day: 27);

      final result = engine.compare(
        desired: [later, earlierB, earlierA],
        existing: const [],
      );

      expect(result.toAdd.map((item) => item.syncId).toList(), [
        'shift-a',
        'shift-b',
        'shift-c',
      ]);
    });

    test('rejects duplicate desired Sync IDs', () {
      final first = event(syncId: 'duplicate');
      final second = event(syncId: 'duplicate', title: 'Different event');

      expect(
        () => engine.compare(desired: [first, second], existing: const []),
        throwsArgumentError,
      );
    });

    test('rejects duplicate existing Sync IDs', () {
      final first = event(syncId: 'duplicate');
      final second = event(syncId: 'duplicate', title: 'Different event');

      expect(
        () => engine.compare(desired: const [], existing: [first, second]),
        throwsArgumentError,
      );
    });

    test('rejects an empty Sync ID', () {
      final invalid = event(syncId: '   ');

      expect(
        () => engine.compare(desired: [invalid], existing: const []),
        throwsArgumentError,
      );
    });
  });
}
