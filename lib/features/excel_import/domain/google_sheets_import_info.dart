import 'worksheet_info.dart';

/// Metadata required to import a Google Sheets spreadsheet.
class GoogleSheetsImportInfo {
  /// Creates immutable Google Sheets import metadata.
  GoogleSheetsImportInfo({
    required this.spreadsheetId,
    required this.title,
    required this.locale,
    required this.timeZone,
    required List<WorksheetInfo> worksheets,
  }) : worksheets = List.unmodifiable(worksheets);

  /// The provider-assigned spreadsheet identifier.
  final String spreadsheetId;

  /// The user-facing spreadsheet title.
  final String title;

  /// The spreadsheet locale, when supplied by Google Sheets.
  final String? locale;

  /// The spreadsheet time zone, when supplied by Google Sheets.
  final String? timeZone;

  /// Worksheets available for selection.
  final List<WorksheetInfo> worksheets;

  /// Number of available worksheets.
  int get worksheetCount => worksheets.length;
}
