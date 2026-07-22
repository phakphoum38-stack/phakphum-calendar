import 'sync_history_entry.dart';

abstract interface class SyncHistoryRepository {
  Future<void> save(SyncHistoryEntry entry);

  Future<List<SyncHistoryEntry>> list({int limit = 100});

  Future<SyncHistoryEntry?> findById(String id);
}
