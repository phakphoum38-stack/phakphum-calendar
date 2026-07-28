class MonthlyRosterSection {
  const MonthlyRosterSection({
    required this.title,
    required this.headerRowIndex,
    required this.assignments,
  });

  final String title;
  final int headerRowIndex;
  final List<MonthlyRosterAssignment> assignments;
}

class MonthlyRosterAssignment {
  const MonthlyRosterAssignment({
    required this.sectionTitle,
    required this.rowLabel,
    required this.workerName,
    required this.date,
    required this.sourceCell,
    this.backgroundColor,
  });

  final String sectionTitle;
  final String rowLabel;
  final String workerName;
  final DateTime date;
  final String sourceCell;
  final String? backgroundColor;
}

class MonthlyRosterParseReport {
  const MonthlyRosterParseReport({
    required this.sections,
    required this.warnings,
  });

  final List<MonthlyRosterSection> sections;
  final List<String> warnings;

  List<MonthlyRosterAssignment> get assignments => [
    for (final section in sections) ...section.assignments,
  ];
}
