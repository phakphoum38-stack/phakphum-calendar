import '../../../domain/entities/schedule.dart';
import 'coverage_requirement.dart';
import 'schedule_conflict.dart';

class GenerationResult {
  GenerationResult({
    required this.schedule,
    required List<ScheduleConflict> conflicts,
    required List<CoverageRequirement> uncoveredRequirements,
    required this.assignmentsCreated,
  }) : conflicts = List.unmodifiable(conflicts),
       uncoveredRequirements = List.unmodifiable(uncoveredRequirements);

  final Schedule schedule;
  final List<ScheduleConflict> conflicts;
  final List<CoverageRequirement> uncoveredRequirements;
  final int assignmentsCreated;

  bool get completed =>
      uncoveredRequirements.isEmpty &&
      !conflicts.any(
        (conflict) => conflict.severity == ScheduleConflictSeverity.error,
      );
}
