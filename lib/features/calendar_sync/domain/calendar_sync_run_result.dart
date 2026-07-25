import '../../diff_engine/domain/calendar_diff.dart';
import '../domain/calendar_event_record.dart';
import '../domain/calendar_sync_command.dart';
import '../domain/calendar_sync_execution_result.dart';

class CalendarSyncRunResult {
  const CalendarSyncRunResult({
    required this.existingRecords,
    required this.diff,
    required this.commands,
    required this.executionResults,
    required this.dryRun,
  });

  final List<CalendarEventRecord> existingRecords;
  final CalendarDiff diff;
  final List<CalendarSyncCommand> commands;
  final List<CalendarSyncExecutionResult> executionResults;
  final bool dryRun;

  int get createCount => _commandCount(CalendarSyncAction.create);

  int get updateCount => _commandCount(CalendarSyncAction.update);

  int get deleteCount => _commandCount(CalendarSyncAction.delete);

  int get skipCount => _commandCount(CalendarSyncAction.skip);

  int get successCount {
    return executionResults.where((result) => result.succeeded).length;
  }

  int get failureCount {
    return executionResults.where((result) => !result.succeeded).length;
  }

  int get appliedCount {
    return executionResults.where((result) => result.applied).length;
  }

  bool get hasFailures => failureCount > 0;

  int _commandCount(CalendarSyncAction action) {
    return commands.where((command) => command.action == action).length;
  }
}
