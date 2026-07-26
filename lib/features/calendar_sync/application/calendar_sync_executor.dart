import '../domain/calendar_event_repository.dart';
import '../domain/calendar_sync_command.dart';
import '../domain/calendar_sync_execution_result.dart';
import '../domain/calendar_sync_progress.dart';

class CalendarSyncExecutor {
  const CalendarSyncExecutor({required this.repository});

  final CalendarEventRepository repository;

  Future<List<CalendarSyncExecutionResult>> execute({
    required List<CalendarSyncCommand> commands,
    required bool dryRun,
    bool continueOnError = false,
    CalendarSyncProgressCallback? onProgress,
  }) async {
    final results = <CalendarSyncExecutionResult>[];
    final total = commands.length;

    for (var index = 0; index < commands.length; index++) {
      final command = commands[index];
      late final CalendarSyncExecutionResult result;

      if (dryRun) {
        result = CalendarSyncExecutionResult.dryRun(command);
        results.add(result);

        _reportProgress(
          onProgress: onProgress,
          result: result,
          completed: index + 1,
          total: total,
        );

        continue;
      }

      try {
        result = await _executeCommand(command);
        results.add(result);
      } catch (error) {
        result = CalendarSyncExecutionResult.failure(
          command: command,
          error: error,
        );

        results.add(result);

        _reportProgress(
          onProgress: onProgress,
          result: result,
          completed: index + 1,
          total: total,
        );

        if (!continueOnError) {
          break;
        }

        continue;
      }

      _reportProgress(
        onProgress: onProgress,
        result: result,
        completed: index + 1,
        total: total,
      );
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

  void _reportProgress({
    required CalendarSyncProgressCallback? onProgress,
    required CalendarSyncExecutionResult result,
    required int completed,
    required int total,
  }) {
    onProgress?.call(
      CalendarSyncProgress(
        stage: CalendarSyncStage.executing,
        message: _progressMessage(result),
        completed: completed,
        total: total,
      ),
    );
  }

  String _progressMessage(CalendarSyncExecutionResult result) {
    final action = result.command.action.name;
    final syncId = result.command.candidate.syncId;

    if (!result.succeeded) {
      return 'Failed to $action event: $syncId';
    }

    if (!result.applied) {
      return 'Checked event: $syncId';
    }

    return 'Completed $action event: $syncId';
  }

  String _requireProviderEventId(CalendarSyncCommand command) {
    final providerEventId = command.providerEventId?.trim();

    if (providerEventId == null || providerEventId.isEmpty) {
      throw StateError('${command.action.name} requires a provider event ID.');
    }

    return providerEventId;
  }
}
