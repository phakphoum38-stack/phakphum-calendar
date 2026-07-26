import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_sync/application/calendar_sync_service.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_record.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_repository.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  CalendarEventCandidate event({
    required String syncId,
    String title = 'Morning shift',
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
      description: 'Radiology',
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

  group('CalendarSyncService', () {
    test('creates a new event from start to finish', () async {
      final repository = FakeCalendarEventRepository();
      final service = CalendarSyncService(repository: repository);

      final desired = event(syncId: 'shift-create');

      final result = await service.sync(
        desiredEvents: <CalendarEventCandidate>[desired],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
      );

      expect(repository.listCallCount, 1);
      expect(repository.createdCandidates, <CalendarEventCandidate>[desired]);

      expect(result.createCount, 1);
      expect(result.updateCount, 0);
      expect(result.deleteCount, 0);
      expect(result.skipCount, 0);
      expect(result.successCount, 1);
      expect(result.failureCount, 0);
      expect(result.appliedCount, 1);
      expect(result.hasFailures, isFalse);
    });

    test('updates an existing changed event', () async {
      final existing = event(syncId: 'shift-update', title: 'Old shift');

      final desired = event(syncId: 'shift-update', title: 'New shift');

      final repository = FakeCalendarEventRepository(
        records: <CalendarEventRecord>[
          record(providerEventId: 'google-update-001', candidate: existing),
        ],
      );

      final service = CalendarSyncService(repository: repository);

      final result = await service.sync(
        desiredEvents: <CalendarEventCandidate>[desired],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
      );

      expect(repository.updatedProviderEventIds, <String>['google-update-001']);

      expect(repository.updatedCandidates, <CalendarEventCandidate>[desired]);

      expect(result.updateCount, 1);
      expect(result.appliedCount, 1);
    });

    test('deletes an event missing from desired events', () async {
      final existing = event(syncId: 'shift-delete');

      final repository = FakeCalendarEventRepository(
        records: <CalendarEventRecord>[
          record(providerEventId: 'google-delete-001', candidate: existing),
        ],
      );

      final service = CalendarSyncService(repository: repository);

      final result = await service.sync(
        desiredEvents: const <CalendarEventCandidate>[],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
      );

      expect(repository.deletedProviderEventIds, <String>['google-delete-001']);

      expect(result.deleteCount, 1);
      expect(result.appliedCount, 1);
    });

    test('skips an unchanged event', () async {
      final existing = event(syncId: 'shift-skip');

      final repository = FakeCalendarEventRepository(
        records: <CalendarEventRecord>[
          record(providerEventId: 'google-skip-001', candidate: existing),
        ],
      );

      final service = CalendarSyncService(repository: repository);

      final result = await service.sync(
        desiredEvents: <CalendarEventCandidate>[existing],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
      );

      expect(result.skipCount, 1);
      expect(result.successCount, 1);
      expect(result.appliedCount, 0);

      expect(repository.createdCandidates, isEmpty);
      expect(repository.updatedCandidates, isEmpty);
      expect(repository.deletedProviderEventIds, isEmpty);
    });

    test('dry run plans changes without modifying repository', () async {
      final existing = event(syncId: 'shift-update', title: 'Old shift');

      final desired = event(syncId: 'shift-update', title: 'New shift');

      final repository = FakeCalendarEventRepository(
        records: <CalendarEventRecord>[
          record(providerEventId: 'google-update-001', candidate: existing),
        ],
      );

      final service = CalendarSyncService(repository: repository);

      final result = await service.sync(
        desiredEvents: <CalendarEventCandidate>[desired],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.updateCount, 1);
      expect(result.successCount, 1);
      expect(result.appliedCount, 0);

      expect(repository.updatedCandidates, isEmpty);
      expect(repository.deletedProviderEventIds, isEmpty);
      expect(repository.createdCandidates, isEmpty);
    });

    test('passes the requested time range to repository', () async {
      final repository = FakeCalendarEventRepository();
      final service = CalendarSyncService(repository: repository);

      final timeMin = DateTime(2026, 7, 1);
      final timeMax = DateTime(2026, 8, 1);

      await service.sync(
        desiredEvents: const <CalendarEventCandidate>[],
        timeMin: timeMin,
        timeMax: timeMax,
      );

      expect(repository.lastTimeMin, timeMin);
      expect(repository.lastTimeMax, timeMax);
    });

    test('rejects an invalid time range', () async {
      final repository = FakeCalendarEventRepository();
      final service = CalendarSyncService(repository: repository);

      expect(
        () => service.sync(
          desiredEvents: const <CalendarEventCandidate>[],
          timeMin: DateTime(2026, 8, 1),
          timeMax: DateTime(2026, 7, 1),
        ),
        throwsArgumentError,
      );

      expect(repository.listCallCount, 0);
    });

    test('continues after a repository operation fails', () async {
      final first = event(syncId: 'shift-a', day: 26);

      final second = event(syncId: 'shift-b', day: 27);

      final repository = FakeCalendarEventRepository(
        createFailuresBySyncId: <String>{'shift-a'},
      );

      final service = CalendarSyncService(repository: repository);

      final result = await service.sync(
        desiredEvents: <CalendarEventCandidate>[first, second],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
        continueOnError: true,
      );

      expect(result.createCount, 2);
      expect(result.failureCount, 1);
      expect(result.successCount, 1);
      expect(result.appliedCount, 1);
      expect(result.hasFailures, isTrue);

      expect(repository.createdCandidates, <CalendarEventCandidate>[second]);
    });

    test('stops after first failure by default', () async {
      final first = event(syncId: 'shift-a', day: 26);

      final second = event(syncId: 'shift-b', day: 27);

      final repository = FakeCalendarEventRepository(
        createFailuresBySyncId: <String>{'shift-a'},
      );

      final service = CalendarSyncService(repository: repository);

      final result = await service.sync(
        desiredEvents: <CalendarEventCandidate>[first, second],
        timeMin: DateTime(2026, 7, 1),
        timeMax: DateTime(2026, 8, 1),
      );

      expect(result.createCount, 2);
      expect(result.executionResults, hasLength(1));
      expect(result.failureCount, 1);
      expect(repository.createdCandidates, isEmpty);
    });
  });
}

class FakeCalendarEventRepository implements CalendarEventRepository {
  FakeCalendarEventRepository({
    List<CalendarEventRecord> records = const <CalendarEventRecord>[],
    Set<String> createFailuresBySyncId = const <String>{},
  }) : _records = List<CalendarEventRecord>.from(records),
       _createFailuresBySyncId = Set<String>.from(createFailuresBySyncId);

  final List<CalendarEventRecord> _records;
  final Set<String> _createFailuresBySyncId;

  final List<CalendarEventCandidate> createdCandidates =
      <CalendarEventCandidate>[];

  final List<CalendarEventCandidate> updatedCandidates =
      <CalendarEventCandidate>[];

  final List<String> updatedProviderEventIds = <String>[];
  final List<String> deletedProviderEventIds = <String>[];

  int listCallCount = 0;
  int nextCreatedId = 1;

  DateTime? lastTimeMin;
  DateTime? lastTimeMax;

  @override
  Future<List<CalendarEventRecord>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    listCallCount++;
    lastTimeMin = timeMin;
    lastTimeMax = timeMax;

    return List<CalendarEventRecord>.unmodifiable(_records);
  }

  @override
  Future<String> createEvent(CalendarEventCandidate candidate) async {
    if (_createFailuresBySyncId.contains(candidate.syncId)) {
      throw StateError('Create failed for ${candidate.syncId}.');
    }

    createdCandidates.add(candidate);

    final providerEventId = 'created-${nextCreatedId++}';

    _records.add(
      CalendarEventRecord(
        providerEventId: providerEventId,
        candidate: candidate,
      ),
    );

    return providerEventId;
  }

  @override
  Future<void> updateEvent({
    required String providerEventId,
    required CalendarEventCandidate candidate,
  }) async {
    updatedProviderEventIds.add(providerEventId);
    updatedCandidates.add(candidate);
  }

  @override
  Future<void> deleteEvent({required String providerEventId}) async {
    deletedProviderEventIds.add(providerEventId);
  }
}
