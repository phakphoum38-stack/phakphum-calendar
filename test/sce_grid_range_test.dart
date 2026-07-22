import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/grid_range.dart';

void main() {
  test('merged range uses end-exclusive coordinates', () {
    const range = SheetGridRange(
      sheetId: 1,
      startRowIndex: 2,
      endRowIndex: 4,
      startColumnIndex: 3,
      endColumnIndex: 5,
    );

    expect(range.contains(rowIndex: 2, columnIndex: 3), isTrue);
    expect(range.contains(rowIndex: 3, columnIndex: 4), isTrue);
    expect(range.contains(rowIndex: 4, columnIndex: 4), isFalse);
    expect(range.contains(rowIndex: 3, columnIndex: 5), isFalse);
    expect(range.rowCount, 2);
    expect(range.columnCount, 2);
  });
}
