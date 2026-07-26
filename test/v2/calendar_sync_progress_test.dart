import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_sync/application/calendar_sync_service.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_record.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_event_repository.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_sync_progress.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  CalendarEventCandidate event({required String syncId, int day = 26}) {
    return CalendarEventCandidate(
      syncId: syncId,
      title: 'Morning shift',
      start: DateTime(2026, 7, day, 8),
      end: DateTime(2026, 7, day, 16),
      shouldExist: true,
      description: 'Radiology',
    );
  }

  test('reports synchronization progress in order', () async {
    final repository = ProgressTestRepository();
    final service = CalendarSyncService(repository: repository);
    final progressEvents = <CalendarSyncProgress>[];

    final result = await service.sync(
      desiredEvents: <CalendarEventCandidate>[
        event(syncId: 'shift-a'),
        event(syncId: 'shift-b', day: 27),
      ],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
      onProgress: progressEvents.add,
    );

    expect(
      progressEvents.map((progress) => progress.stage).toList(),
      <CalendarSyncStage>[
        CalendarSyncStage.loading,
        CalendarSyncStage.comparing,
        CalendarSyncStage.planning,
        CalendarSyncStage.executing,
        CalendarSyncStage.executing,
        CalendarSyncStage.completed,
      ],
    );

    expect(progressEvents[3].completed, 1);
    expect(progressEvents[3].total, 2);
    expect(progressEvents[3].fraction, 0.5);

    expect(progressEvents[4].completed, 2);
    expect(progressEvents[4].fraction, 1);

    expect(progressEvents.last.isCompleted, isTrue);
    expect(progressEvents.last.fraction, 1);

    expect(result.summary.createCount, 2);
    expect(result.summary.successCount, 2);
    expect(result.summary.failureCount, 0);
    expect(result.summary.appliedCount, 2);
    expect(result.summary.executedCount, 2);
    expect(result.summary.plannedCount, 2);
    expect(result.summary.pendingCount, 0);
    expect(result.summary.succeeded, isTrue);
  });

  test('summary reports pending commands after failure', () async {
    final repository = ProgressTestRepository(
      failingSyncIds: <String>{'shift-a'},
    );

    final service = CalendarSyncService(repository: repository);

    final result = await service.sync(
      desiredEvents: <CalendarEventCandidate>[
        event(syncId: 'shift-a'),
        event(syncId: 'shift-b', day: 27),
      ],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
    );

    expect(result.summary.plannedCount, 2);
    expect(result.summary.executedCount, 1);
    expect(result.summary.pendingCount, 1);
    expect(result.summary.failureCount, 1);
    expect(result.summary.hasFailures, isTrue);
    expect(result.summary.succeeded, isFalse);
  });

  test('dry run does not apply changes', () async {
    final repository = ProgressTestRepository();
    final service = CalendarSyncService(repository: repository);

    final result = await service.sync(
      desiredEvents: <CalendarEventCandidate>[event(syncId: 'shift-dry-run')],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
      dryRun: true,
    );

    expect(result.summary.dryRun, isTrue);
    expect(result.summary.successCount, 1);
    expect(result.summary.appliedCount, 0);
    expect(repository.createdEvents, isEmpty);
  });
}

class ProgressTestRepository implements CalendarEventRepository {
  ProgressTestRepository({Set<String> failingSyncIds = const <String>{}})
    : _failingSyncIds = Set<String>.from(failingSyncIds);

  final Set<String> _failingSyncIds;

  final List<CalendarEventCandidate> createdEvents = <CalendarEventCandidate>[];

  @override
  Future<List<CalendarEventRecord>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    return const <CalendarEventRecord>[];
  }

  @override
  Future<String> createEvent(CalendarEventCandidate candidate) async {
    if (_failingSyncIds.contains(candidate.syncId)) {
      throw StateError('Create failed for ${candidate.syncId}.');
    }

    createdEvents.add(candidate);
    return 'provider-${candidate.syncId}';
  }

  @override
  Future<void> updateEvent({
    required String providerEventId,
    required CalendarEventCandidate candidate,
  }) async {}

  @override
  Future<void> deleteEvent({required String providerEventId}) async {}
}
