import '../../../domain/entities/shift_assignment.dart';
import 'rule.dart';
import 'rule_category.dart';
import 'rule_context.dart';
import 'rule_severity.dart';
import 'rule_violation.dart';

abstract class ScheduleRuleBase implements Rule {
  const ScheduleRuleBase({
    required this.id,
    required this.name,
    required this.category,
    this.severity = RuleSeverity.error,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final RuleCategory category;
  @override
  final RuleSeverity severity;

  RuleViolation violation({
    required String message,
    String? employeeId,
    DateTime? date,
  }) {
    return RuleViolation(
      ruleId: id,
      ruleName: name,
      employeeId: employeeId,
      date: date,
      message: message,
      severity: severity,
      category: category,
    );
  }
}

class MaximumShiftsPerMonthRule extends ScheduleRuleBase {
  const MaximumShiftsPerMonthRule({
    required this.maximum,
    super.id = 'maximum-shifts-per-month',
    super.name = 'Maximum shifts per month',
    super.severity,
  }) : super(category: RuleCategory.workload);

  final int maximum;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    final counts = <(String, int, int), int>{};
    for (final entry in context.assignments) {
      final key = (
        entry.assignment.employee.id,
        entry.day.date.year,
        entry.day.date.month,
      );
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return [
      for (final entry in counts.entries)
        if (entry.value > maximum)
          violation(
            employeeId: entry.key.$1,
            date: DateTime(entry.key.$2, entry.key.$3),
            message:
                'Employee ${entry.key.$1} has ${entry.value} shifts; '
                'maximum is $maximum.',
          ),
    ];
  }
}

class MaximumNightShiftsRule extends ScheduleRuleBase {
  const MaximumNightShiftsRule({
    required this.maximum,
    super.id = 'maximum-night-shifts',
    super.name = 'Maximum night shifts',
    super.severity,
  }) : super(category: RuleCategory.nightShift);

  final int maximum;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    final counts = <String, int>{};
    for (final entry in context.assignments) {
      if (entry.assignment.shift.isNightShift) {
        counts.update(
          entry.assignment.employee.id,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return [
      for (final entry in counts.entries)
        if (entry.value > maximum)
          violation(
            employeeId: entry.key,
            message:
                'Employee ${entry.key} has ${entry.value} night shifts; '
                'maximum is $maximum.',
          ),
    ];
  }
}

class MinimumRestHoursRule extends ScheduleRuleBase {
  const MinimumRestHoursRule({
    required this.minimumHours,
    super.id = 'minimum-rest-hours',
    super.name = 'Minimum rest hours',
    super.severity = RuleSeverity.warning,
  }) : super(category: RuleCategory.rest);

  final double minimumHours;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    final byEmployee =
        <String, List<({DateTime start, DateTime end, DateTime date})>>{};
    for (final entry in context.assignments) {
      final start = entry.day.date.add(entry.assignment.shift.startTime);
      var end = entry.day.date.add(entry.assignment.shift.endTime);
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
      byEmployee.putIfAbsent(entry.assignment.employee.id, () => []).add((
        start: start,
        end: end,
        date: entry.day.date,
      ));
    }

    final violations = <RuleViolation>[];
    for (final entry in byEmployee.entries) {
      final shifts = entry.value..sort((a, b) => a.start.compareTo(b.start));
      for (var index = 1; index < shifts.length; index++) {
        final rest = shifts[index].start.difference(shifts[index - 1].end);
        if (!rest.isNegative && rest.inMinutes < (minimumHours * 60).round()) {
          violations.add(
            violation(
              employeeId: entry.key,
              date: shifts[index].date,
              message:
                  'Employee ${entry.key} has '
                  '${(rest.inMinutes / 60).toStringAsFixed(1)} rest hours; '
                  'minimum is $minimumHours.',
            ),
          );
        }
      }
    }
    return violations;
  }
}

class WeekendRule extends ScheduleRuleBase {
  const WeekendRule({
    this.allowed = false,
    super.id = 'weekend-rule',
    super.name = 'Weekend rule',
    super.severity = RuleSeverity.warning,
  }) : super(category: RuleCategory.weekend);

  final bool allowed;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    if (allowed) return const [];
    return [
      for (final entry in context.assignments)
        if (entry.day.date.weekday == DateTime.saturday ||
            entry.day.date.weekday == DateTime.sunday)
          violation(
            employeeId: entry.assignment.employee.id,
            date: entry.day.date,
            message: 'Weekend assignment is not allowed.',
          ),
    ];
  }
}

class HolidayRule extends ScheduleRuleBase {
  const HolidayRule({
    this.allowed = false,
    super.id = 'holiday-rule',
    super.name = 'Holiday rule',
    super.severity = RuleSeverity.warning,
  }) : super(category: RuleCategory.holiday);

  final bool allowed;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    if (allowed) return const [];
    return [
      for (final entry in context.assignments)
        if (entry.day.holidayName != null)
          violation(
            employeeId: entry.assignment.employee.id,
            date: entry.day.date,
            message: 'Assignment on ${entry.day.holidayName} is not allowed.',
          ),
    ];
  }
}

class DepartmentRule extends ScheduleRuleBase {
  DepartmentRule({
    required Set<String> allowedDepartmentIds,
    super.id = 'department-rule',
    super.name = 'Department rule',
    super.severity,
  }) : allowedDepartmentIds = Set.unmodifiable(allowedDepartmentIds),
       super(category: RuleCategory.department);

  final Set<String> allowedDepartmentIds;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    return [
      for (final entry in context.assignments)
        if (!allowedDepartmentIds.contains(
          entry.assignment.employee.department.id,
        ))
          violation(
            employeeId: entry.assignment.employee.id,
            date: entry.day.date,
            message:
                'Department ${entry.assignment.employee.department.name} '
                'is not allowed.',
          ),
    ];
  }
}

class LocationRule extends ScheduleRuleBase {
  LocationRule({
    required Set<String> allowedLocations,
    super.id = 'location-rule',
    super.name = 'Location rule',
    super.severity,
  }) : allowedLocations = Set.unmodifiable(allowedLocations),
       super(category: RuleCategory.location);

  final Set<String> allowedLocations;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    return [
      for (final entry in context.assignments)
        if (entry.assignment.location == null ||
            !allowedLocations.contains(entry.assignment.location))
          violation(
            employeeId: entry.assignment.employee.id,
            date: entry.day.date,
            message:
                'Location ${entry.assignment.location ?? 'not specified'} '
                'is not allowed.',
          ),
    ];
  }
}

typedef CustomRuleEvaluator = List<RuleViolation> Function(RuleContext context);

class CustomRule extends ScheduleRuleBase {
  const CustomRule({
    required super.id,
    required super.name,
    required this.evaluator,
    super.severity,
  }) : super(category: RuleCategory.custom);

  final CustomRuleEvaluator evaluator;

  @override
  List<RuleViolation> evaluate(RuleContext context) => evaluator(context);
}

class DuplicateShiftRule extends ScheduleRuleBase {
  const DuplicateShiftRule({
    super.id = 'duplicate-shifts',
    super.name = 'Duplicate shifts',
    super.severity,
  }) : super(category: RuleCategory.custom);

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    final seen = <String>{};
    final violations = <RuleViolation>[];
    for (final entry in context.assignments) {
      final key =
          '${entry.day.date.toIso8601String()}|'
          '${entry.assignment.employee.id}|${entry.assignment.shift.id}';
      if (!seen.add(key)) {
        violations.add(
          violation(
            employeeId: entry.assignment.employee.id,
            date: entry.day.date,
            message: 'Duplicate shift assignment detected.',
          ),
        );
      }
    }
    return violations;
  }
}

/// Reports assignments whose staff identity is incomplete.
class MissingRequiredStaffRule extends ScheduleRuleBase {
  const MissingRequiredStaffRule({
    super.id = 'missing-required-staff',
    super.name = 'Missing required staff',
    super.severity,
  }) : super(category: RuleCategory.custom);

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    return [
      for (final entry in context.assignments)
        if (!_hasRequiredStaff(entry.assignment))
          violation(
            employeeId: _valueOrNull(entry.assignment.employee.id),
            date: entry.day.date,
            message: 'Assignment must include a valid staff member.',
          ),
    ];
  }
}

/// Reports assignments whose shift duration cannot represent a valid day.
class InvalidShiftDurationRule extends ScheduleRuleBase {
  const InvalidShiftDurationRule({
    super.id = 'invalid-shift-duration',
    super.name = 'Invalid shift duration',
    super.severity,
  }) : super(category: RuleCategory.custom);

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    return [
      for (final entry in context.assignments)
        if (!_hasValidShiftDuration(entry.assignment))
          violation(
            employeeId: _valueOrNull(entry.assignment.employee.id),
            date: entry.day.date,
            message:
                'Shift ${entry.assignment.shift.code.trim().isEmpty ? 'unknown' : entry.assignment.shift.code} '
                'must have working hours greater than 0 and no more than 24.',
          ),
    ];
  }
}

/// Warns when an assignment contains neither staff nor shift information.
class EmptyAssignmentRule extends ScheduleRuleBase {
  const EmptyAssignmentRule({
    super.id = 'empty-assignment',
    super.name = 'Empty assignment',
    super.severity = RuleSeverity.warning,
  }) : super(category: RuleCategory.custom);

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    return [
      for (final entry in context.assignments)
        if (!_hasAnyStaffValue(entry.assignment) &&
            !_hasAnyShiftValue(entry.assignment))
          violation(
            date: entry.day.date,
            message: 'Assignment does not contain staff or shift information.',
          ),
    ];
  }
}

bool _hasRequiredStaff(ShiftAssignment assignment) {
  return assignment.employee.id.trim().isNotEmpty &&
      assignment.employee.fullName.trim().isNotEmpty;
}

bool _hasValidShiftDuration(ShiftAssignment assignment) {
  final shift = assignment.shift;
  const day = Duration(hours: 24);
  return shift.workingHours > 0 &&
      shift.workingHours <= 24 &&
      !shift.startTime.isNegative &&
      shift.startTime < day &&
      !shift.endTime.isNegative &&
      shift.endTime <= day;
}

bool _hasAnyStaffValue(ShiftAssignment assignment) {
  final employee = assignment.employee;
  return [
    employee.id,
    employee.employeeCode,
    employee.firstName,
    employee.lastName,
    employee.nickname,
  ].any((value) => value.trim().isNotEmpty);
}

bool _hasAnyShiftValue(ShiftAssignment assignment) {
  final shift = assignment.shift;
  return [
    shift.id,
    shift.code,
    shift.name,
  ].any((value) => value.trim().isNotEmpty);
}

String? _valueOrNull(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
