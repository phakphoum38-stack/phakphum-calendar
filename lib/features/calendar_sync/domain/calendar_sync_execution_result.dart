import 'calendar_sync_command.dart';

class CalendarSyncExecutionResult {
  const CalendarSyncExecutionResult({
    required this.command,
    required this.succeeded,
    required this.applied,
    this.providerEventId,
    this.error,
  });

  factory CalendarSyncExecutionResult.dryRun(CalendarSyncCommand command) {
    return CalendarSyncExecutionResult(
      command: command,
      succeeded: true,
      applied: false,
      providerEventId: command.providerEventId,
    );
  }

  factory CalendarSyncExecutionResult.success({
    required CalendarSyncCommand command,
    String? providerEventId,
  }) {
    return CalendarSyncExecutionResult(
      command: command,
      succeeded: true,
      applied: command.action != CalendarSyncAction.skip,
      providerEventId: providerEventId ?? command.providerEventId,
    );
  }

  factory CalendarSyncExecutionResult.failure({
    required CalendarSyncCommand command,
    required Object error,
  }) {
    return CalendarSyncExecutionResult(
      command: command,
      succeeded: false,
      applied: false,
      providerEventId: command.providerEventId,
      error: error,
    );
  }

  final CalendarSyncCommand command;
  final bool succeeded;
  final bool applied;
  final String? providerEventId;
  final Object? error;
}
