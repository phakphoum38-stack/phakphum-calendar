class MonthlyRosterSection {
  const MonthlyRosterSection({
    required this.title,
    required this.headerRowIndex,
    required this.assignments,
    this.startDate,
    this.endDate,
  });

  final String title;
  final int headerRowIndex;
  final List<MonthlyRosterAssignment> assignments;
  final DateTime? startDate;
  final DateTime? endDate;
}

class MonthlyRosterAssignment {
  const MonthlyRosterAssignment({
    required this.sectionTitle,
    required this.rowLabel,
    required this.rowIndex,
    required this.workerName,
    required this.date,
    required this.sourceCell,
    this.backgroundColor,
  });

  final String sectionTitle;
  final String rowLabel;
  final int rowIndex;
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

  List<({DateTime start, DateTime end})> get dateRanges {
    final unique = <String, ({DateTime start, DateTime end})>{};
    for (final section in sections) {
      final start = section.startDate;
      final end = section.endDate;
      if (start == null || end == null) continue;
      unique['${start.toIso8601String()}|${end.toIso8601String()}'] = (
        start: start,
        end: end,
      );
    }
    return unique.values.toList()
      ..sort((left, right) => left.start.compareTo(right.start));
  }

  MonthlyRosterParseReport filtered({
    String query = '',
    String? sectionTitle,
    bool Function(DateTime date)? includesDate,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final filteredSections = <MonthlyRosterSection>[];

    for (final section in sections) {
      if (sectionTitle != null && section.title != sectionTitle) continue;
      final sectionMatches = section.title.toLowerCase().contains(
        normalizedQuery,
      );
      final filteredAssignments = section.assignments
          .where((assignment) {
            if (includesDate != null && !includesDate(assignment.date)) {
              return false;
            }
            return normalizedQuery.isEmpty ||
                sectionMatches ||
                assignment.rowLabel.toLowerCase().contains(normalizedQuery) ||
                assignment.workerName.toLowerCase().contains(normalizedQuery);
          })
          .toList(growable: false);
      if (filteredAssignments.isEmpty) continue;
      filteredSections.add(
        MonthlyRosterSection(
          title: section.title,
          headerRowIndex: section.headerRowIndex,
          assignments: List.unmodifiable(filteredAssignments),
          startDate: section.startDate,
          endDate: section.endDate,
        ),
      );
    }

    return MonthlyRosterParseReport(
      sections: List.unmodifiable(filteredSections),
      warnings: warnings,
    );
  }
}
