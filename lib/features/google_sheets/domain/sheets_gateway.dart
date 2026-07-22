import 'spreadsheet_snapshot.dart';

abstract interface class SheetsGateway {
  Future<SpreadsheetSnapshot> readSpreadsheet({
    required String spreadsheetId,
    bool includeGridData = true,
  });
}
