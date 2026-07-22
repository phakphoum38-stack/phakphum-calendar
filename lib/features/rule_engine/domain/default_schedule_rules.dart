import 'schedule_rule.dart';

class OverlappingShiftRule implements ScheduleRule {
  const OverlappingShiftRule();

  @override
  String get id => 'overlapping-shifts';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    final sorted = [...shifts]..sort((a, b) => a.start.compareTo(b.start));
    final violations = <RuleViolation>[];
    for (var index = 1; index < sorted.length; index++) {
      final previous = sorted[index - 1];
      final current = sorted[index];
      if (previous.staffId == current.staffId &&
          current.start.isBefore(previous.end)) {
        violations.add(
          RuleViolation(
            ruleId: id,
            message: 'พบเวรซ้อนกันของบุคลากร ${current.staffId}',
            severity: RuleSeverity.blocking,
            shiftIds: [previous.id, current.id],
          ),
        );
      }
    }
    return violations;
  }
}

class MinimumRestRule implements ScheduleRule {
  const MinimumRestRule({this.minimumRest = const Duration(hours: 8)});

  final Duration minimumRest;

  @override
  String get id => 'minimum-rest';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    final byStaff = <String, List<ScheduledShift>>{};
    for (final shift in shifts) {
      byStaff.putIfAbsent(shift.staffId, () => []).add(shift);
    }

    final violations = <RuleViolation>[];
    for (final entry in byStaff.entries) {
      final sorted = entry.value..sort((a, b) => a.start.compareTo(b.start));
      for (var index = 1; index < sorted.length; index++) {
        final previous = sorted[index - 1];
        final current = sorted[index];
        final rest = current.start.difference(previous.end);
        if (!rest.isNegative && rest < minimumRest) {
          violations.add(
            RuleViolation(
              ruleId: id,
              message:
                  'เวลาพักของ ${entry.key} ต่ำกว่า ${minimumRest.inHours} ชั่วโมง',
              severity: RuleSeverity.warning,
              shiftIds: [previous.id, current.id],
            ),
          );
        }
      }
    }
    return violations;
  }
}

class MaximumWeeklyHoursRule implements ScheduleRule {
  const MaximumWeeklyHoursRule({this.maximumHours = 48});

  final int maximumHours;

  @override
  String get id => 'maximum-weekly-hours';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    final totals = <String, Duration>{};
    final ids = <String, List<String>>{};
    for (final shift in shifts) {
      totals.update(
        shift.staffId,
        (value) => value + shift.duration,
        ifAbsent: () => shift.duration,
      );
      ids.putIfAbsent(shift.staffId, () => []).add(shift.id);
    }

    return totals.entries
        .where((entry) => entry.value > Duration(hours: maximumHours))
        .map(
          (entry) => RuleViolation(
            ruleId: id,
            message:
                '${entry.key} ทำงาน ${entry.value.inHours} ชั่วโมง เกิน $maximumHours ชั่วโมง',
            severity: RuleSeverity.warning,
            shiftIds: ids[entry.key]!,
          ),
        )
        .toList(growable: false);
  }
}
