import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_diff.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_sync_progress.dart';
import 'package:phakphum_calendar/features/calendar_sync/domain/calendar_sync_run_result.dart';
import 'package:phakphum_calendar/features/calendar_sync/presentation/controllers/calendar_sync_controller.dart';

void main() {
  CalendarSyncRunResult createResult({required bool dryRun}) {
    return CalendarSyncRunResult(
      existingRecords: const [],
      diff: const CalendarDiff(
        toAdd: [],
        toUpdate: [],
        toDelete: [],
        unchanged: [],
      ),
      commands: const [],
      executionResults: const [],
      dryRun: dryRun,
    );
  }

  test('preview calls sync operation with dryRun true', () async {
    bool? receivedDryRun;

    final controller = CalendarSyncController(
      syncOperation:
          ({
            required desiredEvents,
            required timeMin,
            required timeMax,
            dryRun = false,
            continueOnError = false,
            onProgress,
          }) async {
            receivedDryRun = dryRun;

            onProgress?.call(
              const CalendarSyncProgress(
                stage: CalendarSyncStage.completed,
                message: 'Preview completed.',
                completed: 1,
                total: 1,
              ),
            );

            return createResult(dryRun: dryRun);
          },
      desiredEvents: const [],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
    );

    await controller.preview();

    expect(receivedDryRun, isTrue);
    expect(controller.status, CalendarSyncStatus.previewReady);
    expect(controller.previewResult, isNotNull);
    expect(controller.previewResult!.dryRun, isTrue);
    expect(controller.progressPercent, 100);

    controller.dispose();
  });

  test('sync calls sync operation with dryRun false', () async {
    bool? receivedDryRun;

    final controller = CalendarSyncController(
      syncOperation:
          ({
            required desiredEvents,
            required timeMin,
            required timeMax,
            dryRun = false,
            continueOnError = false,
            onProgress,
          }) async {
            receivedDryRun = dryRun;
            return createResult(dryRun: dryRun);
          },
      desiredEvents: const [],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
    );

    await controller.sync();

    expect(receivedDryRun, isFalse);
    expect(controller.status, CalendarSyncStatus.success);
    expect(controller.syncResult, isNotNull);
    expect(controller.syncResult!.dryRun, isFalse);

    controller.dispose();
  });

  test('controller receives progress updates', () async {
    final controller = CalendarSyncController(
      syncOperation:
          ({
            required desiredEvents,
            required timeMin,
            required timeMax,
            dryRun = false,
            continueOnError = false,
            onProgress,
          }) async {
            onProgress?.call(
              const CalendarSyncProgress(
                stage: CalendarSyncStage.executing,
                message: 'Applying calendar changes.',
                completed: 2,
                total: 4,
              ),
            );

            return createResult(dryRun: dryRun);
          },
      desiredEvents: const [],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
    );

    await controller.sync();

    expect(controller.progressFraction, 0.5);
    expect(controller.progressPercent, 50);
    expect(controller.progressMessage, 'Applying calendar changes.');

    controller.dispose();
  });

  test('controller stores service error', () async {
    final controller = CalendarSyncController(
      syncOperation:
          ({
            required desiredEvents,
            required timeMin,
            required timeMax,
            dryRun = false,
            continueOnError = false,
            onProgress,
          }) {
            throw StateError('service failed');
          },
      desiredEvents: const [],
      timeMin: DateTime(2026, 7, 1),
      timeMax: DateTime(2026, 8, 1),
    );

    await expectLater(controller.sync, throwsA(isA<StateError>()));

    expect(controller.status, CalendarSyncStatus.failure);
    expect(controller.hasError, isTrue);
    expect(controller.errorMessage, contains('service failed'));

    controller.dispose();
  });

  test('rejects invalid time range', () {
    expect(
      () => CalendarSyncController(
        syncOperation:
            ({
              required desiredEvents,
              required timeMin,
              required timeMax,
              dryRun = false,
              continueOnError = false,
              onProgress,
            }) async {
              return createResult(dryRun: dryRun);
            },
        desiredEvents: const [],
        timeMin: DateTime(2026, 8, 1),
        timeMax: DateTime(2026, 7, 1),
      ),
      throwsArgumentError,
    );
  });
}
