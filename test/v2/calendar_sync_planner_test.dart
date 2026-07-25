import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_sync/application/calendar_sync_planner.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_record.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_sync_command.dart';
import 'package:phakphum_calendar/features/diff_engine/application/calendar_diff_engine.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  const diffEngine = CalendarDiffEngine();
  const planner = CalendarSyncPlanner();

  CalendarEventCandidate candidate({
    required String syncId,
    String title = 'เวรเช้า',
    int day = 26,
    int startHour = 8,
    int endHour = 16,
    bool shouldExist = true,
  }) {
    return CalendarEventCandidate(
      syncId: syncId,
      title: title,
      start: DateTime(2026, 7, day, startHour),
      end: DateTime(2026, 7, day, endHour),
      shouldExist: shouldExist,
      description: 'แผนกรังสีวิทยา',
    );
  }

  CalendarEventRecord record({
    required String providerEventId,
    required CalendarEventCandidate candidate,
  }) {
    return CalendarEventRecord(
      providerEventId: providerEventId,
      candidate: candidate,
    );
  }

  group('CalendarSyncPlanner', () {
    test('creates a create command for a new event', () {
      final desired = candidate(syncId: 'shift-create');

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[desired],
        existing: const <CalendarEventCandidate>[],
      );

      final commands = planner.plan(
        diff: diff,
        existingRecords: const <CalendarEventRecord>[],
      );

      expect(commands, hasLength(1));
      expect(commands.single.action, CalendarSyncAction.create);
      expect(commands.single.candidate, same(desired));
      expect(commands.single.providerEventId, isNull);
    });

    test('creates an update command with provider event ID', () {
      final existing = candidate(syncId: 'shift-update', title: 'เวรเดิม');

      final desired = candidate(syncId: 'shift-update', title: 'เวรใหม่');

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[desired],
        existing: <CalendarEventCandidate>[existing],
      );

      final commands = planner.plan(
        diff: diff,
        existingRecords: <CalendarEventRecord>[
          record(providerEventId: 'google-update-001', candidate: existing),
        ],
      );

      expect(commands, hasLength(1));
      expect(commands.single.action, CalendarSyncAction.update);
      expect(commands.single.candidate, same(desired));
      expect(commands.single.providerEventId, 'google-update-001');
    });

    test('creates a delete command with provider event ID', () {
      final existing = candidate(syncId: 'shift-delete');

      final diff = diffEngine.compare(
        desired: const <CalendarEventCandidate>[],
        existing: <CalendarEventCandidate>[existing],
      );

      final commands = planner.plan(
        diff: diff,
        existingRecords: <CalendarEventRecord>[
          record(providerEventId: 'google-delete-001', candidate: existing),
        ],
      );

      expect(commands, hasLength(1));
      expect(commands.single.action, CalendarSyncAction.delete);
      expect(commands.single.candidate, same(existing));
      expect(commands.single.providerEventId, 'google-delete-001');
    });

    test('creates a skip command for an unchanged event', () {
      final existing = candidate(syncId: 'shift-skip');

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[existing],
        existing: <CalendarEventCandidate>[existing],
      );

      final commands = planner.plan(
        diff: diff,
        existingRecords: <CalendarEventRecord>[
          record(providerEventId: 'google-skip-001', candidate: existing),
        ],
      );

      expect(commands, hasLength(1));
      expect(commands.single.action, CalendarSyncAction.skip);
      expect(commands.single.providerEventId, 'google-skip-001');
    });

    test('plans create update delete and skip commands together', () {
      final createCandidate = candidate(syncId: 'shift-create', day: 26);

      final oldUpdateCandidate = candidate(
        syncId: 'shift-update',
        title: 'เวรเดิม',
        day: 27,
      );

      final newUpdateCandidate = candidate(
        syncId: 'shift-update',
        title: 'เวรใหม่',
        day: 27,
      );

      final deleteCandidate = candidate(syncId: 'shift-delete', day: 28);

      final unchangedCandidate = candidate(syncId: 'shift-skip', day: 29);

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[
          createCandidate,
          newUpdateCandidate,
          unchangedCandidate,
        ],
        existing: <CalendarEventCandidate>[
          oldUpdateCandidate,
          deleteCandidate,
          unchangedCandidate,
        ],
      );

      final commands = planner.plan(
        diff: diff,
        existingRecords: <CalendarEventRecord>[
          record(
            providerEventId: 'google-update',
            candidate: oldUpdateCandidate,
          ),
          record(providerEventId: 'google-delete', candidate: deleteCandidate),
          record(providerEventId: 'google-skip', candidate: unchangedCandidate),
        ],
      );

      expect(
        commands.map((command) => command.action).toList(),
        <CalendarSyncAction>[
          CalendarSyncAction.create,
          CalendarSyncAction.update,
          CalendarSyncAction.delete,
          CalendarSyncAction.skip,
        ],
      );
    });

    test('throws when update record is missing', () {
      final existing = candidate(syncId: 'missing-update', title: 'เก่า');

      final desired = candidate(syncId: 'missing-update', title: 'ใหม่');

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[desired],
        existing: <CalendarEventCandidate>[existing],
      );

      expect(
        () => planner.plan(
          diff: diff,
          existingRecords: const <CalendarEventRecord>[],
        ),
        throwsStateError,
      );
    });

    test('throws when delete record is missing', () {
      final existing = candidate(syncId: 'missing-delete');

      final diff = diffEngine.compare(
        desired: const <CalendarEventCandidate>[],
        existing: <CalendarEventCandidate>[existing],
      );

      expect(
        () => planner.plan(
          diff: diff,
          existingRecords: const <CalendarEventRecord>[],
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate existing record Sync IDs', () {
      final existing = candidate(syncId: 'duplicate');

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[existing],
        existing: <CalendarEventCandidate>[existing],
      );

      expect(
        () => planner.plan(
          diff: diff,
          existingRecords: <CalendarEventRecord>[
            record(providerEventId: 'google-001', candidate: existing),
            record(providerEventId: 'google-002', candidate: existing),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty provider event ID', () {
      final existing = candidate(syncId: 'empty-provider');

      final diff = diffEngine.compare(
        desired: <CalendarEventCandidate>[existing],
        existing: <CalendarEventCandidate>[existing],
      );

      expect(
        () => planner.plan(
          diff: diff,
          existingRecords: <CalendarEventRecord>[
            record(providerEventId: '   ', candidate: existing),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
