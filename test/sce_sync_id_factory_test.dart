import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/sync_id_factory.dart';

void main() {
  test('creates stable deterministic sync IDs', () {
    const factory = SyncIdFactory();

    final first = factory.create(
      spreadsheetId: 'sheet-123',
      sheetId: 9,
      cellA1: 'b12',
      date: DateTime(2026, 8, 4, 19),
      category: 'ER',
      period: 'เช้า',
    );

    final second = factory.create(
      spreadsheetId: 'sheet-123',
      sheetId: 9,
      cellA1: 'B12',
      date: DateTime(2026, 8, 4),
      category: 'er',
      period: 'เช้า',
    );

    expect(first, second);
    expect(first.startsWith('sce-'), isTrue);
  });
}
