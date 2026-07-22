import '../domain/sync_history_entry.dart';
import '../domain/sync_history_repository.dart';

class InMemorySyncHistoryRepository
    implements SyncHistoryRepository {
  final Map<String, SyncHistoryEntry> _entries =
      <String, SyncHistoryEntry>{};

  @override
  Future<SyncHistoryEntry?> findById(String id) async {
    return _entries[id];
  }

  @override
  Future<List<SyncHistoryEntry>> list({
    int limit = 100,
  }) async {
    final values = _entries.values.toList()
      ..sort(
        (left, right) =>
            right.startedAt.compareTo(left.startedAt),
      );

    return values.take(limit).toList(growable: false);
  }

  @override
  Future<void> save(SyncHistoryEntry entry) async {
    _entries[entry.id] = entry;
  }
}
