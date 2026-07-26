import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/schedule_month.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../domain/coverage_requirement.dart';
import '../domain/department_capacity.dart';
import '../domain/employee_availability.dart';
import '../domain/generation_result.dart';
import 'conflict_detection_service.dart';
import 'coverage_checking_service.dart';
import 'schedule_assignment_writer.dart';

class ManualScheduleService {
  const ManualScheduleService({
    this.conflictDetection = const ConflictDetectionService(),
    this.coverageChecking = const CoverageCheckingService(),
    this.writer = const ScheduleAssignmentWriter(),
  });

  final ConflictDetectionService conflictDetection;
  final CoverageCheckingService coverageChecking;
  final ScheduleAssignmentWriter writer;

  GenerationResult assign({
    required Schedule schedule,
    required DateTime date,
    required ShiftAssignment assignment,
    List<EmployeeAvailability> availability = const [],
    List<DepartmentCapacity> capacities = const [],
    List<CoverageRequirement> coverageRequirements = const [],
  }) {
    final month = schedule.month(date) ?? ScheduleMonth.empty(date);
    final day = month.day(date) ?? ScheduleDay(date: date);
    final conflicts = conflictDetection.validateProposedAssignment(
      day: day,
      assignment: assignment,
      availability: availability,
      capacities: capacities,
    );
    final hasErrors = conflicts.isNotEmpty;
    final updated = hasErrors
        ? schedule
        : writer.add(schedule: schedule, date: date, assignment: assignment);
    return GenerationResult(
      schedule: updated,
      conflicts: conflicts,
      uncoveredRequirements: coverageChecking.uncovered(
        updated,
        coverageRequirements,
      ),
      assignmentsCreated: hasErrors ? 0 : 1,
    );
  }
}
