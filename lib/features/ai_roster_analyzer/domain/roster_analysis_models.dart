/// Domain models for the AI-assisted roster analyzer.
///
/// This layer is intentionally pure Dart and does not call a remote AI service.
/// It normalizes duty information from Excel workbooks, Google Sheets,
/// calendar events, pasted tables, and manually entered tables into one
/// canonical daily roster structure.

enum RosterAnalysisSourceType {
  excelWorkbook,
  googleSheet,
  calendar,
  pastedTable,
  manualTable,
}

enum RosterDutyKind {
  /// Normal shift/duty assignment.
  primaryDuty,

  /// Staff assigned as the regular/default owner of a role.
  regularStaff,

  /// Staff replacing another person or receiving an exchanged shift.
  replacement,

  /// Extra helper, add-site/add-side support, backup, or reinforcement.
  extraStaff,

  /// Explicit off-duty/off/rest day.
  offDuty,

  /// Approved or requested leave.
  leave,

  /// Missing, absent, no-show, or not available for the day.
  absent,

  /// A shift received from another person.
  receivedExchange,

  /// A shift given to another person.
  givenExchange,

  /// On-site/site assignment.
  onsite,

  /// The analyzer found a row but could not classify it confidently.
  unknown,
}

class RosterAnalysisSource {
  const RosterAnalysisSource({
    required this.type,
    required this.name,
    this.sheetName,
    this.range,
    this.calendarId,
  });

  final RosterAnalysisSourceType type;
  final String name;
  final String? sheetName;
  final String? range;
  final String? calendarId;
}

class RosterInputFrame {
  const RosterInputFrame({
    required this.source,
    required this.columns,
    required this.rows,
  });

  final RosterAnalysisSource source;
  final List<String> columns;
  final List<Map<String, String>> rows;
}

class RosterAnalysisRecord {
  const RosterAnalysisRecord({
    required this.date,
    required this.kind,
    required this.source,
    required this.rawText,
    this.personName,
    this.roleLabel,
    this.siteLabel,
    this.relatedPersonName,
    this.confidence = 0.5,
    this.notes = const [],
    this.rawCells = const {},
  });

  final DateTime date;
  final RosterDutyKind kind;
  final RosterAnalysisSource source;
  final String rawText;
  final String? personName;
  final String? roleLabel;
  final String? siteLabel;
  final String? relatedPersonName;
  final double confidence;
  final List<String> notes;
  final Map<String, String> rawCells;

  RosterAnalysisRecord copyWith({
    DateTime? date,
    RosterDutyKind? kind,
    RosterAnalysisSource? source,
    String? rawText,
    String? personName,
    String? roleLabel,
    String? siteLabel,
    String? relatedPersonName,
    double? confidence,
    List<String>? notes,
    Map<String, String>? rawCells,
  }) {
    return RosterAnalysisRecord(
      date: date ?? this.date,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      rawText: rawText ?? this.rawText,
      personName: personName ?? this.personName,
      roleLabel: roleLabel ?? this.roleLabel,
      siteLabel: siteLabel ?? this.siteLabel,
      relatedPersonName: relatedPersonName ?? this.relatedPersonName,
      confidence: confidence ?? this.confidence,
      notes: notes ?? this.notes,
      rawCells: rawCells ?? this.rawCells,
    );
  }
}

class DailyRosterPlan {
  const DailyRosterPlan({
    required this.date,
    required this.records,
    required this.warnings,
  });

  final DateTime date;
  final List<RosterAnalysisRecord> records;
  final List<String> warnings;

  Iterable<RosterAnalysisRecord> byKind(RosterDutyKind kind) =>
      records.where((record) => record.kind == kind);

  Iterable<RosterAnalysisRecord> get dutyRecords => records.where(
    (record) =>
        record.kind == RosterDutyKind.primaryDuty ||
        record.kind == RosterDutyKind.regularStaff ||
        record.kind == RosterDutyKind.replacement ||
        record.kind == RosterDutyKind.extraStaff ||
        record.kind == RosterDutyKind.onsite,
  );

  Iterable<RosterAnalysisRecord> get unavailableRecords => records.where(
    (record) =>
        record.kind == RosterDutyKind.offDuty ||
        record.kind == RosterDutyKind.leave ||
        record.kind == RosterDutyKind.absent,
  );
}

class RosterAnalysisResult {
  const RosterAnalysisResult({
    required this.records,
    required this.dailyPlans,
    required this.warnings,
  });

  final List<RosterAnalysisRecord> records;
  final List<DailyRosterPlan> dailyPlans;
  final List<String> warnings;

  bool get hasWarnings => warnings.isNotEmpty ||
      dailyPlans.any((plan) => plan.warnings.isNotEmpty);
}
