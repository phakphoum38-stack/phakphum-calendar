enum ScheduleConflictType {
  duplicateAssignment,
  overlappingShift,
  unavailableEmployee,
  departmentCapacity,
  insufficientCoverage,
}

enum ScheduleConflictSeverity { warning, error }

class ScheduleConflict {
  const ScheduleConflict({
    required this.type,
    required this.message,
    required this.severity,
    this.employeeId,
    this.date,
    this.requirementId,
  });

  final ScheduleConflictType type;
  final String message;
  final ScheduleConflictSeverity severity;
  final String? employeeId;
  final DateTime? date;
  final String? requirementId;
}
