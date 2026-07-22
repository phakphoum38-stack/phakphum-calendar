import 'package:shared_preferences/shared_preferences.dart';
import '../domain/failed_sync_operation.dart';
import '../domain/failed_sync_repository.dart';
import 'failed_sync_json_codec.dart';

class SharedPreferencesFailedSyncRepository
    implements FailedSyncRepository {
  SharedPreferencesFailedSyncRepository({
    SharedPreferencesAsync? preferences,
    FailedSyncJsonCodec codec = const FailedSyncJsonCodec(),
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _codec = codec;

  static const keyPrefix = 'sce.failed_sync.v1.';
  final SharedPreferencesAsync _preferences;
  final FailedSyncJsonCodec _codec;

  String _key(String historyId) => '$keyPrefix$historyId';

  @override
  Future<void> clearHistory(String historyId) =>
      _preferences.remove(_key(historyId));

  @override
  Future<List<FailedSyncOperation>> listForHistory(String historyId) async =>
      _codec.decode(await _preferences.getString(_key(historyId)));

  @override
  Future<void> replaceForHistory(
    String historyId,
    List<FailedSyncOperation> operations,
  ) async {
    if (operations.isEmpty) {
      await clearHistory(historyId);
      return;
    }
    await _preferences.setString(_key(historyId), _codec.encode(operations));
  }
}
