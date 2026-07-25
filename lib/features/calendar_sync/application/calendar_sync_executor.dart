import '../domain/calendar_event_repository.dart';
import '../domain/calendar_sync_command.dart';
import '../domain/calendar_sync_execution_result.dart';

class CalendarSyncExecutor {
  const CalendarSyncExecutor({required this.repository});

  final CalendarEventRepository repository;

  Future<List<CalendarSyncExecutionResult>> execute({
    required List<CalendarSyncCommand> commands,
    required bool dryRun,
    bool continueOnError = false,
  }) async {
    final results = <CalendarSyncExecutionResult>[];

    for (final command in commands) {
      if (dryRun) {
        results.add(CalendarSyncExecutionResult.dryRun(command));
        continue;
      }

      try {
        final result = await _executeCommand(command);
        results.add(result);
      } catch (error) {
        results.add(
          CalendarSyncExecutionResult.failure(command: command, error: error),
        );

        if (!continueOnError) {
          break;
        }
      }
    }

    return List<CalendarSyncExecutionResult>.unmodifiable(results);
  }

  Future<CalendarSyncExecutionResult> _executeCommand(
    CalendarSyncCommand command,
  ) async {
    switch (command.action) {
      case CalendarSyncAction.create:
        final providerEventId = await repository.createEvent(command.candidate);

        return CalendarSyncExecutionResult.success(
          command: command,
          providerEventId: providerEventId,
        );

      case CalendarSyncAction.update:
        final providerEventId = _requireProviderEventId(command);

        await repository.updateEvent(
          providerEventId: providerEventId,
          candidate: command.candidate,
        );

        return CalendarSyncExecutionResult.success(
          command: command,
          providerEventId: providerEventId,
        );

      case CalendarSyncAction.delete:
        final providerEventId = _requireProviderEventId(command);

        await repository.deleteEvent(providerEventId: providerEventId);

        return CalendarSyncExecutionResult.success(
          command: command,
          providerEventId: providerEventId,
        );

      case CalendarSyncAction.skip:
        return CalendarSyncExecutionResult.success(command: command);
    }
  }

  String _requireProviderEventId(CalendarSyncCommand command) {
    final providerEventId = command.providerEventId?.trim();

    if (providerEventId == null || providerEventId.isEmpty) {
      throw StateError('${command.action.name} requires a provider event ID.');
    }

    return providerEventId;
  }
}
