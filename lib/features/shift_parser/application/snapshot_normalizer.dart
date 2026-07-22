import '../../google_sheets/domain/grid_range.dart';
import '../../google_sheets/domain/sheet_cell.dart';
import '../../google_sheets/domain/spreadsheet_snapshot.dart';
import '../domain/normalized_cell.dart';
import '../domain/shift_parser_input.dart';

class SnapshotNormalizer {
  const SnapshotNormalizer();

  List<ShiftParserInput> normalize(SpreadsheetSnapshot snapshot) {
    return snapshot.sheets
        .map(
          (sheet) => ShiftParserInput(
            spreadsheetId: snapshot.spreadsheetId,
            spreadsheetTitle: snapshot.title,
            sheetId: sheet.sheetId,
            sheetTitle: sheet.title,
            timeZone: snapshot.timeZone,
            cells: sheet.cells
                .map(
                  (cell) => _normalizeCell(
                    cell: cell,
                    sheetTitle: sheet.title,
                    mergedRanges: sheet.mergedRanges,
                  ),
                )
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  NormalizedCell _normalizeCell({
    required SheetCell cell,
    required String sheetTitle,
    required List<SheetGridRange> mergedRanges,
  }) {
    SheetGridRange? mergedRange;

    for (final range in mergedRanges) {
      if (range.contains(
        rowIndex: cell.rowIndex,
        columnIndex: cell.columnIndex,
      )) {
        mergedRange = range;
        break;
      }
    }

    return NormalizedCell(
      sheetId: cell.sheetId,
      sheetTitle: sheetTitle,
      a1: cell.a1,
      rowIndex: cell.rowIndex,
      columnIndex: cell.columnIndex,
      text: cell.normalizedText,
      rawValue: cell.rawValue,
      backgroundColor: cell.backgroundColor,
      isMerged: mergedRange != null,
      mergedAnchorA1: cell.mergedAnchorA1,
    );
  }
}
