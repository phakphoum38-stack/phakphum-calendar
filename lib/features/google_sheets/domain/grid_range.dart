class SheetGridRange {
  const SheetGridRange({
    required this.sheetId,
    required this.startRowIndex,
    required this.endRowIndex,
    required this.startColumnIndex,
    required this.endColumnIndex,
  });

  final int sheetId;
  final int startRowIndex;
  final int endRowIndex;
  final int startColumnIndex;
  final int endColumnIndex;

  int get rowCount => endRowIndex - startRowIndex;
  int get columnCount => endColumnIndex - startColumnIndex;

  bool contains({
    required int rowIndex,
    required int columnIndex,
  }) {
    return rowIndex >= startRowIndex &&
        rowIndex < endRowIndex &&
        columnIndex >= startColumnIndex &&
        columnIndex < endColumnIndex;
  }

  bool get isSingleCell => rowCount == 1 && columnCount == 1;
}
