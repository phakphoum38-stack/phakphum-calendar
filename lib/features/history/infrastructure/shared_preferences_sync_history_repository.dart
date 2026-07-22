import 'package:shared_preferences/shared_preferences.dart';
import '../domain/sync_history_entry.dart';
import '../domain/sync_history_repository.dart';
import 'sync_history_json_codec.dart';

class SharedPreferencesSyncHistoryRepository
    implements SyncHistoryRepository {
  SharedPreferencesSyncHistoryRepository({
    SharedPreferencesAsync? preferences,
    SyncHistoryJsonCodec codec = const SyncHistoryJsonCodec(),
    this.maximumEntries = 100,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _codec = codec;

  static const storageKey = 'sce.sync_history.v1';
  final SharedPreferencesAsync _preferences;
  final SyncHistoryJsonCodec _codec;
  final int maximumEntries;

  @override
  Future<SyncHistoryEntry?> findById(String id) async {
    for (final entry in await list(limit: maximumEntries)) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<List<SyncHistoryEntry>> list({int limit = 100}) async {
    final entries = _codec.decodeList(
      await _preferences.getString(storageKey),
    ).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return entries.take(limit).toList(growable: false);
  }

  @override
  Future<void> save(SyncHistoryEntry entry) async {
    final current = await list(limit: maximumEntries);
    final updated = <SyncHistoryEntry>[
      entry,
      ...current.where((item) => item.id != entry.id),
    ].take(maximumEntries).toList(growable: false);
    await _preferences.setString(storageKey, _codec.encodeList(updated));
  }
}
