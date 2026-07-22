import '../../history/domain/sync_history_entry.dart';
import '../../history/domain/sync_history_repository.dart';
import '../domain/calendar_sync_gateway.dart';
import '../domain/calendar_sync_operation_result.dart';
import '../domain/failed_sync_operation.dart';
import '../domain/failed_sync_repository.dart';

class ResumeSyncResult {
  const ResumeSyncResult({
    required this.historyEntry,
    required this.operations,
  });
  final SyncHistoryEntry historyEntry;
  final List<CalendarSyncOperationResult> operations;
  bool get completed => operations.every((item) => item.success);
}

class ResumeSyncService {
  const ResumeSyncService({
    required CalendarSyncGateway gateway,
    required SyncHistoryRepository historyRepository,
    required FailedSyncRepository failedRepository,
  }) : _gateway = gateway,
       _historyRepository = historyRepository,
       _failedRepository = failedRepository;

  final CalendarSyncGateway _gateway;
  final SyncHistoryRepository _historyRepository;
  final FailedSyncRepository _failedRepository;

  Future<ResumeSyncResult> resume(String historyId) async {
    final original = await _historyRepository.findById(historyId);
    if (original == null) throw StateError('Sync history entry not found.');
    final failed = await _failedRepository.listForHistory(historyId);
    final remaining = <FailedSyncOperation>[];
    final results = <CalendarSyncOperationResult>[];
    var inserted = original.inserted;
    var updated = original.updated;
    var deleted = original.deleted;

    for (final item in failed) {
      try {
        if (item.type == CalendarSyncOperationType.insert) {
          final command = item.command;
          if (command == null) throw StateError('Insert command missing.');
          await _gateway.insert(command);
          inserted++;
        } else if (item.type == CalendarSyncOperationType.update) {
          final command = item.command;
          final eventId = item.eventId;
          if (command == null || eventId == null) {
            throw StateError('Update payload incomplete.');
          }
          await _gateway.update(eventId: eventId, command: command);
          updated++;
        } else {
          final eventId = item.eventId;
          if (eventId == null) throw StateError('Delete event ID missing.');
          await _gateway.delete(eventId: eventId, calendarId: item.calendarId);
          deleted++;
        }
        results.add(
          CalendarSyncOperationResult(
            type: item.type,
            referenceId: item.referenceId,
            success: true,
          ),
        );
      } catch (error) {
        remaining.add(
          FailedSyncOperation(
            historyId: item.historyId,
            type: item.type,
            referenceId: item.referenceId,
            attempts: item.attempts + 1,
            command: item.command,
            eventId: item.eventId,
            calendarId: item.calendarId,
            message: error.toString(),
          ),
        );
        results.add(
          CalendarSyncOperationResult(
            type: item.type,
            referenceId: item.referenceId,
            success: false,
            message: error.toString(),
          ),
        );
      }
    }

    await _failedRepository.replaceForHistory(historyId, remaining);
    final history = original.copyWith(
      finishedAt: DateTime.now(),
      status: remaining.isEmpty
          ? SyncHistoryStatus.success
          : SyncHistoryStatus.partialSuccess,
      inserted: inserted,
      updated: updated,
      deleted: deleted,
      failed: remaining.length,
      message: remaining.isEmpty
          ? 'All failed operations resumed successfully.'
          : '${remaining.length} operation(s) still failed.',
    );
    await _historyRepository.save(history);
    return ResumeSyncResult(historyEntry: history, operations: results);
  }
}
