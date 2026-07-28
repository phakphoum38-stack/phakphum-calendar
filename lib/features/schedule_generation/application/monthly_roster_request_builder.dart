import '../../../domain/entities/schedule.dart';
import '../domain/coverage_requirement.dart';
import '../domain/generation_request.dart';
import '../domain/monthly_roster_blueprint.dart';
import '../domain/roster_staffing_rule.dart';
import '../domain/staff_directory.dart';
import '../domain/staff_group.dart';
import 'radiology_roster_blueprint.dart';

class MonthlyRosterRequestBuilder {
  const MonthlyRosterRequestBuilder();

  GenerationRequest build({
    required DateTime month,
    required StaffDirectory directory,
    required MonthlyRosterBlueprint blueprint,
    required List<RosterStaffingRule> staffingRules,
  }) {
    final normalizedMonth = DateTime(month.year, month.month);
    final schedule = const _EmptyScheduleFactory().create(normalizedMonth);
    final slotsById = {for (final slot in blueprint.slots) slot.id: slot};
    final requirements = <CoverageRequirement>[];
    final lastDay = DateTime(month.year, month.month + 1, 0).day;

    for (final rule in staffingRules) {
      final slot = slotsById[rule.slotId];
      if (slot == null) {
        throw ArgumentError.value(rule.slotId, 'staffingRules.slotId');
      }
      if (!slot.allowedGroups.contains(rule.staffGroup)) {
        throw ArgumentError(
          '${rule.staffGroup.name} is not allowed for ${slot.id}.',
        );
      }
      for (var day = 1; day <= lastDay; day++) {
        final date = DateTime(month.year, month.month, day);
        if (!rule.weekdays.contains(date.weekday)) continue;
        requirements.add(
          CoverageRequirement(
            id:
                '${date.toIso8601String().substring(0, 10)}|'
                '${slot.id}|${rule.staffGroup.id}',
            date: date,
            departmentId: rule.staffGroup.id,
            shiftTypeId: slot.shiftTypeId,
            requiredEmployees: rule.requiredEmployees,
            location: slot.location,
          ),
        );
      }
    }

    return GenerationRequest(
      schedule: schedule,
      month: normalizedMonth,
      employees: directory.allEmployees,
      shiftTypes: blueprint.shiftTypes,
      coverageRequirements: requirements,
    );
  }
}

class _EmptyScheduleFactory {
  const _EmptyScheduleFactory();

  Schedule create(DateTime month) =>
      const RadiologyRosterBlueprint().emptySchedule(month);
}
