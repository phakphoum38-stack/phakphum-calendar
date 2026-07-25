import 'schedule_rule.dart';

class InvalidShiftTimeRule implements ScheduleRule {
  const InvalidShiftTimeRule();

  @override
  String get id => 'unknown_shift_time';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    return shifts
        .where((shift) => !shift.hasValidTimeRange)
        .map(
          (shift) => RuleViolation(
            ruleId: id,
            message:
                'เน€เธงเธฃ ${shift.id} เธกเธตเธเนเธงเธเน€เธงเธฅเธฒเนเธกเนเธ–เธนเธเธ•เนเธญเธ เน€เธงเธฅเธฒเธชเธดเนเธเธชเธธเธ”เธ•เนเธญเธเธญเธขเธนเนเธซเธฅเธฑเธเน€เธงเธฅเธฒเน€เธฃเธดเนเธกเธ•เนเธ',
            severity: RuleSeverity.blocking,
            shiftIds: [shift.id],
          ),
        )
        .toList(growable: false);
  }
}

class OverlappingShiftRule implements ScheduleRule {
  const OverlappingShiftRule();

  @override
  String get id => 'overlapping-shifts';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    final shiftsByStaff = <String, List<ScheduledShift>>{};

    for (final shift in shifts.where((item) => item.hasValidTimeRange)) {
      shiftsByStaff.putIfAbsent(shift.staffId, () => []).add(shift);
    }

    final violations = <RuleViolation>[];

    for (final entry in shiftsByStaff.entries) {
      final staffShifts = [...entry.value]
        ..sort((a, b) => a.start.compareTo(b.start));

      for (var firstIndex = 0; firstIndex < staffShifts.length; firstIndex++) {
        final first = staffShifts[firstIndex];

        for (
          var secondIndex = firstIndex + 1;
          secondIndex < staffShifts.length;
          secondIndex++
        ) {
          final second = staffShifts[secondIndex];

          if (!second.start.isBefore(first.end)) {
            break;
          }

          final overlaps =
              first.start.isBefore(second.end) &&
              second.start.isBefore(first.end);

          if (overlaps) {
            violations.add(
              RuleViolation(
                ruleId: id,
                message:
                    'เธเธเน€เธงเธฃเธเนเธญเธเธเธฑเธเธเธญเธเธเธเธฑเธเธเธฒเธ ${entry.key}: ${first.id} เนเธฅเธฐ ${second.id}',
                severity: RuleSeverity.blocking,
                shiftIds: [first.id, second.id],
              ),
            );
          }
        }
      }
    }

    return violations;
  }
}

class MinimumRestRule implements ScheduleRule {
  const MinimumRestRule({this.minimumRest = const Duration(hours: 8)});

  final Duration minimumRest;

  @override
  String get id => 'afternoon_to_morning';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    final shiftsByStaff = <String, List<ScheduledShift>>{};

    for (final shift in shifts.where((item) => item.hasValidTimeRange)) {
      shiftsByStaff.putIfAbsent(shift.staffId, () => []).add(shift);
    }

    final violations = <RuleViolation>[];

    for (final entry in shiftsByStaff.entries) {
      final staffShifts = [...entry.value]
        ..sort((a, b) => a.start.compareTo(b.start));

      for (var index = 1; index < staffShifts.length; index++) {
        final previous = staffShifts[index - 1];
        final current = staffShifts[index];

        if (current.start.isBefore(previous.end)) {
          continue;
        }

        final restDuration = current.start.difference(previous.end);

        if (restDuration < minimumRest) {
          violations.add(
            RuleViolation(
              ruleId: id,
              message:
                  'เธเธเธฑเธเธเธฒเธ ${entry.key} เธกเธตเน€เธงเธฅเธฒเธเธฑเธ ${restDuration.inHours} เธเธฑเนเธงเนเธกเธ '
                  'เธเธถเนเธเธ•เนเธณเธเธงเนเธฒเธเธฑเนเธเธ•เนเธณ ${minimumRest.inHours} เธเธฑเนเธงเนเธกเธ',
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
  String get id => 'maximum_weekly_hours';

  @override
  List<RuleViolation> evaluate(List<ScheduledShift> shifts) {
    final weeklyDurations = <String, Duration>{};
    final weeklyShiftIds = <String, List<String>>{};
    final weeklyStaffIds = <String, String>{};
    final weeklyStartDates = <String, DateTime>{};

    for (final shift in shifts.where((item) => item.hasValidTimeRange)) {
      final weekStart = _startOfWeek(shift.start);
      final bucketKey =
          '${shift.staffId}:${weekStart.toIso8601String().substring(0, 10)}';

      weeklyDurations.update(
        bucketKey,
        (current) => current + shift.duration,
        ifAbsent: () => shift.duration,
      );

      weeklyShiftIds.putIfAbsent(bucketKey, () => []).add(shift.id);
      weeklyStaffIds[bucketKey] = shift.staffId;
      weeklyStartDates[bucketKey] = weekStart;
    }

    final violations = <RuleViolation>[];

    for (final entry in weeklyDurations.entries) {
      if (entry.value <= Duration(hours: maximumHours)) {
        continue;
      }

      final staffId = weeklyStaffIds[entry.key]!;
      final weekStart = weeklyStartDates[entry.key]!;

      violations.add(
        RuleViolation(
          ruleId: id,
          message:
              'เธเธเธฑเธเธเธฒเธ $staffId เธ—เธณเธเธฒเธ ${entry.value.inHours} เธเธฑเนเธงเนเธกเธ '
              'เนเธเธชเธฑเธเธ”เธฒเธซเนเธ—เธตเนเน€เธฃเธดเนเธกเธงเธฑเธเธ—เธตเน ${_formatDate(weekStart)} '
              'เน€เธเธดเธเธเธณเธซเธเธ” $maximumHours เธเธฑเนเธงเนเธกเธ',
          severity: RuleSeverity.warning,
          shiftIds: List.unmodifiable(weeklyShiftIds[entry.key]!),
        ),
      );
    }

    return violations;
  }

  DateTime _startOfWeek(DateTime dateTime) {
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
