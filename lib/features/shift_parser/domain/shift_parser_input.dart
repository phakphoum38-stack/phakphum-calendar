import 'normalized_cell.dart';

class ShiftParserInput {
  const ShiftParserInput({
    required this.spreadsheetId,
    required this.spreadsheetTitle,
    required this.sheetId,
    required this.sheetTitle,
    required this.timeZone,
    required this.cells,
  });

  final String spreadsheetId;
  final String spreadsheetTitle;
  final int sheetId;
  final String sheetTitle;
  final String? timeZone;
  final List<NormalizedCell> cells;
}
