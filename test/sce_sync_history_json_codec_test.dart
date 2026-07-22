import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/history/domain/sync_history_entry.dart';
import 'package:phakphum_calendar/features/history/infrastructure/sync_history_json_codec.dart';

void main() {
  test('round-trips history entries', () {
    const codec = SyncHistoryJsonCodec();
    final source = [
      SyncHistoryEntry(
        id: 'h1',
        startedAt: DateTime(2026, 7, 22),
        status: SyncHistoryStatus.partialSuccess,
        inserted: 1,
        updated: 2,
        deleted: 3,
        failed: 1,
      ),
    ];
    final decoded = codec.decodeList(codec.encodeList(source));
    expect(decoded.single.id, 'h1');
    expect(decoded.single.failed, 1);
  });
}
