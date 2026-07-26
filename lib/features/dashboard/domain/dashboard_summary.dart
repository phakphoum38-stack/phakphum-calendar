import '../../../domain/entities/shift_assignment.dart';

/// Prepared, immutable values displayed by the SCE dashboard.
class DashboardSummary {
  const DashboardSummary({
    required this.todayAssignments,
    required this.tomorrowAssignments,
    required this.monthAssignmentCount,
    required this.conflictCount,
    this.nextAssignment,
    this.nextAssignmentDate,
  });

  final List<ShiftAssignment> todayAssignments;
  final List<ShiftAssignment> tomorrowAssignments;
  final int monthAssignmentCount;
  final int conflictCount;
  final ShiftAssignment? nextAssignment;
  final DateTime? nextAssignmentDate;
}
