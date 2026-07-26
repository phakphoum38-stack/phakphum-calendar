import '../../diff_engine/application/calendar_diff_engine.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../domain/calendar_event_repository.dart';
import '../domain/calendar_sync_progress.dart';
import '../domain/calendar_sync_run_result.dart';
import 'calendar_sync_executor.dart';
import 'calendar_sync_planner.dart';

class CalendarSyncService {
  CalendarSyncService({
    required this.repository,
    this._diffEngine = const CalendarDiffEngine(),
    this._planner = const CalendarSyncPlanner(),
  }) : _executor = CalendarSyncExecutor(repository: repository);

  final CalendarEventRepository repository;
  final CalendarDiffEngine _diffEngine;
  final CalendarSyncPlanner _planner;
  final CalendarSyncExecutor _executor;

  Future<CalendarSyncRunResult> sync({
    required List<CalendarEventCandidate> desiredEvents,
    required DateTime timeMin,
    required DateTime timeMax,
    bool dryRun = false,
    bool continueOnError = false,
    CalendarSyncProgressCallback? onProgress,
  }) async {
    _validateTimeRange(timeMin: timeMin, timeMax: timeMax);

    onProgress?.call(
      const CalendarSyncProgress(
        stage: CalendarSyncStage.loading,
        message: 'Loading managed calendar events.',
        completed: 0,
        total: 0,
      ),
    );

    final existingRecords = await repository.listManagedEvents(
      timeMin: timeMin,
      timeMax: timeMax,
    );

    onProgress?.call(
      CalendarSyncProgress(
        stage: CalendarSyncStage.comparing,
        message: 'Comparing desired and existing events.',
        completed: 0,
        total: desiredEvents.length + existingRecords.length,
      ),
    );

    final existingCandidates = existingRecords
        .map((record) => record.candidate)
        .toList(growable: false);

    final diff = _diffEngine.compare(
      desired: desiredEvents,
      existing: existingCandidates,
    );

    onProgress?.call(
      const CalendarSyncProgress(
        stage: CalendarSyncStage.planning,
        message: 'Preparing synchronization commands.',
        completed: 0,
        total: 0,
      ),
    );

    final commands = _planner.plan(
      diff: diff,
      existingRecords: existingRecords,
    );

    final executionResults = await _executor.execute(
      commands: commands,
      dryRun: dryRun,
      continueOnError: continueOnError,
      onProgress: onProgress,
    );

    final result = CalendarSyncRunResult(
      existingRecords: List.unmodifiable(existingRecords),
      diff: diff,
      commands: commands,
      executionResults: executionResults,
      dryRun: dryRun,
    );

    onProgress?.call(
      CalendarSyncProgress(
        stage: CalendarSyncStage.completed,
        message: result.hasFailures
            ? 'Calendar synchronization completed with errors.'
            : 'Calendar synchronization completed successfully.',
        completed: executionResults.length,
        total: commands.length,
      ),
    );

    return result;
  }

  void _validateTimeRange({
    required DateTime timeMin,
    required DateTime timeMax,
  }) {
    if (!timeMin.isBefore(timeMax)) {
      throw ArgumentError.value(
        timeMax,
        'timeMax',
        'timeMax must be later than timeMin.',
      );
    }
  }
}
