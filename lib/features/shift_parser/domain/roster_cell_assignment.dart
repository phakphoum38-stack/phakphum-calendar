class RosterCellAssignment {
  const RosterCellAssignment({
    required this.spreadsheetId,
    required this.sheetId,
    required this.sheetTitle,
    required this.sourceCell,
    required this.date,
    required this.category,
    required this.period,
    required this.slot,
    required this.workerName,
    this.backgroundColor,
  });

  final String spreadsheetId;
  final int sheetId;
  final String sheetTitle;
  final String sourceCell;
  final DateTime date;
  final String category;
  final String period;
  final String slot;
  final String workerName;
  final String? backgroundColor;

  String get positionKey => [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
    category.trim().toLowerCase(),
    period.trim().toLowerCase(),
    slot.trim().toLowerCase(),
  ].join('|');
}
