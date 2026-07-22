import 'roster_cell_assignment.dart';

class RosterParseReport {
  const RosterParseReport({
    required this.assignments,
    required this.warnings,
    required this.periodStart,
    required this.periodEnd,
  });

  final List<RosterCellAssignment> assignments;
  final List<String> warnings;
  final DateTime periodStart;
  final DateTime periodEnd;
}
