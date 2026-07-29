import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/schedule_month.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../domain/coverage_requirement.dart';
import '../domain/generation_request.dart';
import '../domain/generation_result.dart';
import '../domain/schedule_conflict.dart';
import 'conflict_detection_service.dart';
import 'coverage_checking_service.dart';
import 'schedule_assignment_writer.dart';

class AutoAssignmentService {
  const AutoAssignmentService({
    this.conflictDetection = const ConflictDetectionService(),
    this.coverageChecking = const CoverageCheckingService(),
    this.writer = const ScheduleAssignmentWriter(),
  });

  final ConflictDetectionService conflictDetection;
  final CoverageCheckingService coverageChecking;
  final ScheduleAssignmentWriter writer;

  GenerationResult generate(GenerationRequest request) {
    var schedule = request.schedule;
    var created = 0;
    final conflicts = <ScheduleConflict>[];
    final assignmentCounts = <String, int>{};
    for (final month in schedule.months) {
      for (final day in month.days) {
        for (final assignment in day.assignments) {
          assignmentCounts.update(
            assignment.employee.id,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    final requirements =
        request.coverageRequirements
            .where(
              (requirement) =>
                  requirement.date.year == request.month.year &&
                  requirement.date.month == request.month.month,
            )
            .toList()
          ..sort((left, right) => left.date.compareTo(right.date));

    for (final requirement in requirements) {
      final shift = request.shiftTypes
          .where((item) => item.id == requirement.shiftTypeId)
          .firstOrNull;
      if (shift == null) {
        conflicts.add(_coverageConflict(requirement, 'Shift type not found.'));
        continue;
      }

      var missing =
          requirement.requiredEmployees -
          coverageChecking.assignedCount(schedule, requirement);
      while (missing > 0) {
        final candidates =
            request.employees
                .where(
                  (employee) =>
                      employee.active &&
                      employee.department.id == requirement.departmentId &&
                      _canWorkAt(
                        request.lockedDutyPointsByEmployeeId[employee.id],
                        requirement.location,
                      ),
                )
                .toList()
              ..sort((left, right) {
                final lockComparison =
                    _lockPriority(
                      request.lockedDutyPointsByEmployeeId[right.id],
                      requirement.location,
                    ).compareTo(
                      _lockPriority(
                        request.lockedDutyPointsByEmployeeId[left.id],
                        requirement.location,
                      ),
                    );
                if (lockComparison != 0) return lockComparison;
                final countComparison = (assignmentCounts[left.id] ?? 0)
                    .compareTo(assignmentCounts[right.id] ?? 0);
                return countComparison != 0
                    ? countComparison
                    : left.employeeCode.compareTo(right.employeeCode);
              });

        ShiftAssignment? selected;
        for (final employee in candidates) {
          final assignment = ShiftAssignment(
            employee: employee,
            shift: shift,
            location: requirement.location,
          );
          final month =
              schedule.month(requirement.date) ??
              ScheduleMonth.empty(requirement.date);
          final day =
              month.day(requirement.date) ??
              ScheduleDay(date: requirement.date);
          final assignmentConflicts = conflictDetection
              .validateProposedAssignment(
                day: day,
                assignment: assignment,
                availability: request.availability,
                capacities: request.departmentCapacities,
              );
          if (assignmentConflicts.isEmpty) {
            selected = assignment;
            break;
          }
        }

        if (selected == null) {
          conflicts.add(
            _coverageConflict(
              requirement,
              'No eligible employee is available.',
            ),
          );
          break;
        }

        schedule = writer.add(
          schedule: schedule,
          date: requirement.date,
          assignment: selected,
        );
        assignmentCounts.update(
          selected.employee.id,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        created++;
        missing--;
      }
    }

    final uncovered = coverageChecking.uncovered(schedule, requirements);
    return GenerationResult(
      schedule: schedule,
      conflicts: conflicts,
      uncoveredRequirements: uncovered,
      assignmentsCreated: created,
    );
  }

  bool _canWorkAt(String? lockedPoint, String? requirementPoint) =>
      lockedPoint == null ||
      lockedPoint.trim().isEmpty ||
      lockedPoint.trim() == requirementPoint?.trim();

  int _lockPriority(String? lockedPoint, String? requirementPoint) =>
      lockedPoint != null &&
          lockedPoint.trim().isNotEmpty &&
          lockedPoint.trim() == requirementPoint?.trim()
      ? 1
      : 0;

  ScheduleConflict _coverageConflict(
    CoverageRequirement requirement,
    String reason,
  ) {
    return ScheduleConflict(
      type: ScheduleConflictType.insufficientCoverage,
      message: 'Coverage requirement ${requirement.id}: $reason',
      severity: ScheduleConflictSeverity.error,
      date: requirement.date,
      requirementId: requirement.id,
    );
  }
}
