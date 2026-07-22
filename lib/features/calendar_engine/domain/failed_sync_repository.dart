import 'failed_sync_operation.dart';

abstract interface class FailedSyncRepository {
  Future<void> replaceForHistory(
    String historyId,
    List<FailedSyncOperation> operations,
  );
  Future<List<FailedSyncOperation>> listForHistory(String historyId);
  Future<void> clearHistory(String historyId);
}
