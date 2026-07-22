enum ShiftRelationshipType {
  own,
  other,
  received,
  givenAway,
  majorExchange,
  clinicExchange,
  borrowedFree,
  borrowedPaid,
  unknown,
}

enum ShiftStatus { valid, warning, blocked, removed }

class ShiftRecord {
  const ShiftRecord({
    required this.spreadsheetId,
    required this.sheetId,
    required this.sourceCell,
    required this.date,
    required this.category,
    required this.period,
    required this.start,
    required this.end,
    required this.originalOwner,
    required this.actualWorker,
    required this.relationshipType,
    required this.status,
    required this.syncId,
    this.transferFrom,
    this.transferTo,
    this.backgroundColor,
    this.rawValue,
    this.warnings = const <String>[],
  });

  final String spreadsheetId;
  final int sheetId;
  final String sourceCell;
  final DateTime date;
  final String category;
  final String period;
  final DateTime start;
  final DateTime end;
  final String originalOwner;
  final String actualWorker;
  final String? transferFrom;
  final String? transferTo;
  final ShiftRelationshipType relationshipType;
  final ShiftStatus status;
  final String? backgroundColor;
  final String? rawValue;
  final String syncId;
  final List<String> warnings;
}
