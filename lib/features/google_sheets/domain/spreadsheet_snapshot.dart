import 'grid_range.dart';
import 'sheet_cell.dart';

class SpreadsheetSheetSnapshot {
  const SpreadsheetSheetSnapshot({
    required this.sheetId,
    required this.title,
    required this.rowCount,
    required this.columnCount,
    required this.cells,
    required this.mergedRanges,
  });

  final int sheetId;
  final String title;
  final int rowCount;
  final int columnCount;
  final List<SheetCell> cells;
  final List<SheetGridRange> mergedRanges;

  SheetCell? cellAt({required int rowIndex, required int columnIndex}) {
    for (final cell in cells) {
      if (cell.rowIndex == rowIndex && cell.columnIndex == columnIndex) {
        return cell;
      }
    }
    return null;
  }

  SheetCell? cellByA1(String a1) {
    for (final cell in cells) {
      if (cell.a1.toUpperCase() == a1.toUpperCase()) {
        return cell;
      }
    }
    return null;
  }
}

class SpreadsheetSnapshot {
  const SpreadsheetSnapshot({
    required this.spreadsheetId,
    required this.title,
    required this.locale,
    required this.timeZone,
    required this.sheets,
  });

  final String spreadsheetId;
  final String title;
  final String? locale;
  final String? timeZone;
  final List<SpreadsheetSheetSnapshot> sheets;
}
