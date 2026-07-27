import '../../google_sheets/domain/sheet_cell.dart';
import '../../google_sheets/domain/sheets_gateway.dart';
import '../../google_sheets/domain/spreadsheet_snapshot.dart';
import '../domain/excel_cell.dart';
import '../domain/excel_row.dart';
import '../domain/google_sheets_import_info.dart';
import '../domain/worksheet_info.dart';
import 'spreadsheet_ownership_verifier.dart';

/// Adapts Google Sheets data to the existing tabular import models.
class GoogleSheetsImportDataSource {
  /// Creates an import data source backed by [gateway].
  GoogleSheetsImportDataSource(this.gateway, {required this.ownershipVerifier});

  /// Provider gateway used to read spreadsheet snapshots.
  final SheetsGateway gateway;
  final SpreadsheetOwnershipVerifier ownershipVerifier;

  SpreadsheetSnapshot? _spreadsheet;
  WorksheetInfo? _selectedWorksheet;

  /// The worksheet most recently selected for row conversion.
  WorksheetInfo? get selectedWorksheet => _selectedWorksheet;

  /// Reads spreadsheet metadata and makes its worksheets available.
  Future<GoogleSheetsImportInfo> readMetadata(String spreadsheetId) async {
    await ownershipVerifier.requireCurrentAccountOwnership(spreadsheetId);
    final spreadsheet = await gateway.readSpreadsheet(
      spreadsheetId: spreadsheetId,
    );
    _spreadsheet = spreadsheet;
    _selectedWorksheet = null;

    return GoogleSheetsImportInfo(
      spreadsheetId: spreadsheet.spreadsheetId,
      title: spreadsheet.title,
      locale: spreadsheet.locale,
      timeZone: spreadsheet.timeZone,
      worksheets: _toWorksheetInfo(spreadsheet),
    );
  }

  /// Lists worksheets from the most recently read spreadsheet.
  List<WorksheetInfo> listWorksheets() {
    final spreadsheet = _spreadsheet;
    if (spreadsheet == null) {
      return const [];
    }
    return List.unmodifiable(_toWorksheetInfo(spreadsheet));
  }

  /// Selects [worksheet] and converts its rows to the shared import model.
  ///
  /// When [maxRows] is omitted, every available row is returned. Callers may
  /// pass a limit such as 50 when producing a preview.
  List<ExcelRow> selectWorksheet(WorksheetInfo worksheet, {int? maxRows}) {
    if (maxRows != null && maxRows < 0) {
      throw ArgumentError.value(maxRows, 'maxRows', 'Must not be negative');
    }
    final spreadsheet = _spreadsheet;
    if (spreadsheet == null) {
      throw StateError(
        'Read spreadsheet metadata before selecting a worksheet',
      );
    }
    final sheet = _findSheet(spreadsheet, worksheet.name);
    _selectedWorksheet = worksheet;
    return _convertRows(sheet, maxRows: maxRows);
  }

  List<WorksheetInfo> _toWorksheetInfo(SpreadsheetSnapshot spreadsheet) {
    return [
      for (final sheet in spreadsheet.sheets)
        WorksheetInfo(
          name: sheet.title,
          rowCount: sheet.rowCount,
          columnCount: sheet.columnCount,
        ),
    ];
  }

  SpreadsheetSheetSnapshot _findSheet(
    SpreadsheetSnapshot spreadsheet,
    String worksheetName,
  ) {
    for (final sheet in spreadsheet.sheets) {
      if (sheet.title == worksheetName) {
        return sheet;
      }
    }
    throw StateError('Worksheet "$worksheetName" was not found');
  }

  List<ExcelRow> _convertRows(SpreadsheetSheetSnapshot sheet, {int? maxRows}) {
    if (sheet.cells.isEmpty || maxRows == 0) {
      return const [];
    }
    final lastAvailableRow = sheet.cells.fold<int>(
      0,
      (maximum, cell) => cell.rowIndex > maximum ? cell.rowIndex : maximum,
    );
    final availableRowCount = lastAvailableRow + 1;
    final rowCount = maxRows == null || availableRowCount < maxRows
        ? availableRowCount
        : maxRows;
    final cellsByRow = <int, List<SheetCell>>{};
    for (final cell in sheet.cells) {
      if (cell.rowIndex >= rowCount) {
        continue;
      }
      cellsByRow.putIfAbsent(cell.rowIndex, () => []).add(cell);
    }
    for (final cells in cellsByRow.values) {
      cells.sort(
        (left, right) => left.columnIndex.compareTo(right.columnIndex),
      );
    }

    return [
      for (var rowIndex = 0; rowIndex < rowCount; rowIndex++)
        ExcelRow(
          index: rowIndex,
          cells: [
            for (final cell in cellsByRow[rowIndex] ?? const <SheetCell>[])
              ExcelCell(
                rowIndex: rowIndex,
                columnIndex: cell.columnIndex,
                value: cell.formattedValue ?? cell.rawValue ?? cell.formula,
              ),
          ],
        ),
    ];
  }
}
