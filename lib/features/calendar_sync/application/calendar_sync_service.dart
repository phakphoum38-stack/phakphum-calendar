import '../../diff_engine/application/calendar_diff_engine.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../domain/calendar_event_repository.dart';
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
  }) async {
    _validateTimeRange(timeMin: timeMin, timeMax: timeMax);

    final existingRecords = await repository.listManagedEvents(
      timeMin: timeMin,
      timeMax: timeMax,
    );

    final existingCandidates = existingRecords
        .map((record) => record.candidate)
        .toList(growable: false);

    final diff = _diffEngine.compare(
      desired: desiredEvents,
      existing: existingCandidates,
    );

    final commands = _planner.plan(
      diff: diff,
      existingRecords: existingRecords,
    );

    final executionResults = await _executor.execute(
      commands: commands,
      dryRun: dryRun,
      continueOnError: continueOnError,
    );

    return CalendarSyncRunResult(
      existingRecords: List.unmodifiable(existingRecords),
      diff: diff,
      commands: commands,
      executionResults: executionResults,
      dryRun: dryRun,
    );
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
