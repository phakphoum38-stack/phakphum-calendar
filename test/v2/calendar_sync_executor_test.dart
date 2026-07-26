import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_sync/application/calendar_sync_executor.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_record.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_repository.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_sync_command.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 8);
  final end = DateTime.utc(2026, 7, 26, 16);

  CalendarEventCandidate candidate({
    String syncId = 'shift-001',
    String title = 'เวรเช้า',
    bool shouldExist = true,
  }) {
    return CalendarEventCandidate(
      syncId: syncId,
      title: title,
      start: start,
      end: end,
      shouldExist: shouldExist,
      description: 'แผนกรังสีวิทยา',
    );
  }

  group('CalendarSyncExecutor dry run', () {
    test('does not call repository for create command', () async {
      final repository = FakeCalendarEventRepository();
      final executor = CalendarSyncExecutor(repository: repository);

      final command = CalendarSyncCommand.create(candidate: candidate());

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: true,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isTrue);
      expect(results.single.applied, isFalse);
      expect(results.single.command, same(command));

      expect(repository.createCalls, isEmpty);
      expect(repository.updateCalls, isEmpty);
      expect(repository.deleteCalls, isEmpty);
    });

    test('returns one result for every command', () async {
      final repository = FakeCalendarEventRepository();
      final executor = CalendarSyncExecutor(repository: repository);

      final commands = <CalendarSyncCommand>[
        CalendarSyncCommand.create(candidate: candidate(syncId: 'create-001')),
        CalendarSyncCommand.update(
          providerEventId: 'google-update-001',
          candidate: candidate(syncId: 'update-001'),
        ),
        CalendarSyncCommand.delete(
          providerEventId: 'google-delete-001',
          candidate: candidate(syncId: 'delete-001', shouldExist: false),
        ),
        CalendarSyncCommand.skip(
          candidate: candidate(syncId: 'skip-001'),
          reason: 'No changes',
        ),
      ];

      final results = await executor.execute(commands: commands, dryRun: true);

      expect(results, hasLength(4));
      expect(results.every((result) => result.succeeded), isTrue);
      expect(results.every((result) => !result.applied), isTrue);

      expect(repository.createCalls, isEmpty);
      expect(repository.updateCalls, isEmpty);
      expect(repository.deleteCalls, isEmpty);
    });
  });

  group('CalendarSyncExecutor create', () {
    test('creates an event and returns provider event ID', () async {
      final repository = FakeCalendarEventRepository(
        createdProviderEventId: 'google-created-001',
      );
      final executor = CalendarSyncExecutor(repository: repository);

      final eventCandidate = candidate();
      final command = CalendarSyncCommand.create(candidate: eventCandidate);

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: false,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isTrue);
      expect(results.single.applied, isTrue);
      expect(results.single.providerEventId, 'google-created-001');

      expect(repository.createCalls, <CalendarEventCandidate>[eventCandidate]);
    });
  });

  group('CalendarSyncExecutor update', () {
    test('updates an existing provider event', () async {
      final repository = FakeCalendarEventRepository();
      final executor = CalendarSyncExecutor(repository: repository);

      final eventCandidate = candidate(syncId: 'shift-update-001');

      final command = CalendarSyncCommand.update(
        providerEventId: 'google-event-001',
        candidate: eventCandidate,
      );

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: false,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isTrue);
      expect(results.single.applied, isTrue);
      expect(results.single.providerEventId, 'google-event-001');

      expect(repository.updateCalls, hasLength(1));
      expect(repository.updateCalls.single.providerEventId, 'google-event-001');
      expect(repository.updateCalls.single.candidate, same(eventCandidate));
    });
  });

  group('CalendarSyncExecutor delete', () {
    test('deletes an existing provider event', () async {
      final repository = FakeCalendarEventRepository();
      final executor = CalendarSyncExecutor(repository: repository);

      final command = CalendarSyncCommand.delete(
        providerEventId: 'google-event-delete-001',
        candidate: candidate(syncId: 'shift-delete-001', shouldExist: false),
      );

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: false,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isTrue);
      expect(results.single.applied, isTrue);
      expect(results.single.providerEventId, 'google-event-delete-001');

      expect(repository.deleteCalls, <String>['google-event-delete-001']);
    });
  });

  group('CalendarSyncExecutor skip', () {
    test('does not call repository', () async {
      final repository = FakeCalendarEventRepository();
      final executor = CalendarSyncExecutor(repository: repository);

      final command = CalendarSyncCommand.skip(
        candidate: candidate(syncId: 'shift-skip-001'),
        reason: 'Event is already current.',
      );

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: false,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isTrue);
      expect(results.single.applied, isFalse);

      expect(repository.createCalls, isEmpty);
      expect(repository.updateCalls, isEmpty);
      expect(repository.deleteCalls, isEmpty);
    });
  });

  group('CalendarSyncExecutor errors', () {
    test('stops after the first error by default', () async {
      final repository = FakeCalendarEventRepository(
        createError: StateError('Create failed'),
      );
      final executor = CalendarSyncExecutor(repository: repository);

      final commands = <CalendarSyncCommand>[
        CalendarSyncCommand.create(
          candidate: candidate(syncId: 'failed-create'),
        ),
        CalendarSyncCommand.delete(
          providerEventId: 'google-delete-after-error',
          candidate: candidate(
            syncId: 'delete-after-error',
            shouldExist: false,
          ),
        ),
      ];

      final results = await executor.execute(commands: commands, dryRun: false);

      expect(results, hasLength(1));
      expect(results.single.succeeded, isFalse);
      expect(results.single.applied, isFalse);
      expect(results.single.error, isA<StateError>());

      expect(repository.createCalls, hasLength(1));
      expect(repository.deleteCalls, isEmpty);
    });

    test('continues after an error when continueOnError is true', () async {
      final repository = FakeCalendarEventRepository(
        createError: StateError('Create failed'),
      );
      final executor = CalendarSyncExecutor(repository: repository);

      final commands = <CalendarSyncCommand>[
        CalendarSyncCommand.create(
          candidate: candidate(syncId: 'failed-create'),
        ),
        CalendarSyncCommand.delete(
          providerEventId: 'google-delete-after-error',
          candidate: candidate(
            syncId: 'delete-after-error',
            shouldExist: false,
          ),
        ),
      ];

      final results = await executor.execute(
        commands: commands,
        dryRun: false,
        continueOnError: true,
      );

      expect(results, hasLength(2));

      expect(results.first.succeeded, isFalse);
      expect(results.first.error, isA<StateError>());

      expect(results.last.succeeded, isTrue);
      expect(results.last.applied, isTrue);

      expect(repository.createCalls, hasLength(1));
      expect(repository.deleteCalls, <String>['google-delete-after-error']);
    });

    test('captures update errors', () async {
      final repository = FakeCalendarEventRepository(
        updateError: StateError('Update failed'),
      );
      final executor = CalendarSyncExecutor(repository: repository);

      final command = CalendarSyncCommand.update(
        providerEventId: 'google-update-error',
        candidate: candidate(syncId: 'update-error'),
      );

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: false,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isFalse);
      expect(results.single.applied, isFalse);
      expect(results.single.error, isA<StateError>());
    });

    test('captures delete errors', () async {
      final repository = FakeCalendarEventRepository(
        deleteError: StateError('Delete failed'),
      );
      final executor = CalendarSyncExecutor(repository: repository);

      final command = CalendarSyncCommand.delete(
        providerEventId: 'google-delete-error',
        candidate: candidate(syncId: 'delete-error', shouldExist: false),
      );

      final results = await executor.execute(
        commands: <CalendarSyncCommand>[command],
        dryRun: false,
      );

      expect(results, hasLength(1));
      expect(results.single.succeeded, isFalse);
      expect(results.single.applied, isFalse);
      expect(results.single.error, isA<StateError>());
    });
  });

  group('CalendarSyncCommand validation', () {
    test('trims update provider event ID', () {
      final command = CalendarSyncCommand.update(
        providerEventId: '  google-update-001  ',
        candidate: candidate(),
      );

      expect(command.providerEventId, 'google-update-001');
    });

    test('trims delete provider event ID', () {
      final command = CalendarSyncCommand.delete(
        providerEventId: '  google-delete-001  ',
        candidate: candidate(shouldExist: false),
      );

      expect(command.providerEventId, 'google-delete-001');
    });

    test('rejects an empty update provider event ID', () {
      expect(
        () => CalendarSyncCommand.update(
          providerEventId: '   ',
          candidate: candidate(),
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty delete provider event ID', () {
      expect(
        () => CalendarSyncCommand.delete(
          providerEventId: '',
          candidate: candidate(shouldExist: false),
        ),
        throwsArgumentError,
      );
    });

    test('normalizes an empty optional skip provider ID to null', () {
      final command = CalendarSyncCommand.skip(
        providerEventId: '   ',
        candidate: candidate(),
      );

      expect(command.providerEventId, isNull);
    });
  });
}

class FakeCalendarEventRepository implements CalendarEventRepository {
  FakeCalendarEventRepository({
    this.createdProviderEventId = 'google-created-event',
    this.createError,
    this.updateError,
    this.deleteError,
  });

  final String createdProviderEventId;
  final Object? createError;
  final Object? updateError;
  final Object? deleteError;

  final List<CalendarEventCandidate> createCalls = <CalendarEventCandidate>[];

  final List<UpdateEventCall> updateCalls = <UpdateEventCall>[];

  final List<String> deleteCalls = <String>[];

  @override
  Future<List<CalendarEventRecord>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    return const <CalendarEventRecord>[];
  }

  @override
  Future<String> createEvent(CalendarEventCandidate candidate) async {
    createCalls.add(candidate);

    final error = createError;
    if (error != null) {
      throw error;
    }

    return createdProviderEventId;
  }

  @override
  Future<void> updateEvent({
    required String providerEventId,
    required CalendarEventCandidate candidate,
  }) async {
    updateCalls.add(
      UpdateEventCall(providerEventId: providerEventId, candidate: candidate),
    );

    final error = updateError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> deleteEvent({required String providerEventId}) async {
    deleteCalls.add(providerEventId);

    final error = deleteError;
    if (error != null) {
      throw error;
    }
  }
}

class UpdateEventCall {
  const UpdateEventCall({
    required this.providerEventId,
    required this.candidate,
  });

  final String providerEventId;
  final CalendarEventCandidate candidate;
}
