import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/models/shift_record.dart';

void main() {
  test('ShiftRecord preserves relationship information', () {
    final record = ShiftRecord(
      spreadsheetId: 'spreadsheet',
      sheetId: 1,
      sourceCell: 'J15',
      date: DateTime(2026, 8, 4),
      category: 'CT-ER',
      period: 'บ่าย',
      start: DateTime(2026, 8, 4, 16),
      end: DateTime(2026, 8, 5, 8),
      originalOwner: 'สมชาย',
      actualWorker: 'ภาคภูมิ',
      transferFrom: 'สมชาย',
      relationshipType: ShiftRelationshipType.received,
      status: ShiftStatus.valid,
      syncId: 'example-sync-id',
    );

    expect(record.actualWorker, 'ภาคภูมิ');
    expect(record.relationshipType, ShiftRelationshipType.received);
    expect(record.end.day, 5);
  });
}
