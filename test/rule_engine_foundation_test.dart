import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/domain/entities/department.dart';
import 'package:phakphum_calendar/domain/entities/employee.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/domain/entities/schedule_day.dart';
import 'package:phakphum_calendar/domain/entities/schedule_month.dart';
import 'package:phakphum_calendar/domain/entities/shift_assignment.dart';
import 'package:phakphum_calendar/domain/entities/shift_type.dart';
import 'package:phakphum_calendar/features/rules/application/rule_engine.dart';
import 'package:phakphum_calendar/features/rules/domain/schedule_rules.dart';

void main() {
  group('RuleEngine', () {
    test('detects maximum shifts per month', () {
      final engine = RuleEngine(
        rules: const [MaximumShiftsPerMonthRule(maximum: 2)],
      );
      final schedule = _schedule([
        _day(1, [_dayAssignment]),
        _day(2, [_dayAssignment]),
        _day(3, [_dayAssignment]),
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.passed, isFalse);
      expect(result.errors.single.ruleId, 'maximum-shifts-per-month');
    });

    test('detects maximum night shifts', () {
      final engine = RuleEngine(
        rules: const [MaximumNightShiftsRule(maximum: 1)],
      );
      final schedule = _schedule([
        _day(1, [_nightAssignment]),
        _day(2, [_nightAssignment]),
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.errors.single.ruleId, 'maximum-night-shifts');
    });

    test('detects duplicate shifts', () {
      final engine = RuleEngine(rules: const [DuplicateShiftRule()]);
      final schedule = _schedule([
        _day(1, [_dayAssignment, _dayAssignment]),
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.errors.single.ruleId, 'duplicate-shifts');
    });

    test('detects named holiday assignments', () {
      final engine = RuleEngine(rules: const [HolidayRule()]);
      final schedule = _schedule([
        ScheduleDay(
          date: DateTime(2026, 7, 8),
          holidayName: 'Foundation Day',
          assignments: const [_dayAssignment],
        ),
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.warnings.single.ruleId, 'holiday-rule');
      expect(result.warnings.single.message, contains('Foundation Day'));
    });

    test('detects weekend assignments', () {
      final engine = RuleEngine(rules: const [WeekendRule()]);
      final schedule = _schedule([
        _day(4, [_dayAssignment]), // Saturday, 4 July 2026.
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.warnings.single.ruleId, 'weekend-rule');
    });

    test('detects minimum rest and validates a single employee', () {
      final engine = RuleEngine(
        rules: const [MinimumRestHoursRule(minimumHours: 12)],
      );
      final schedule = _schedule([
        _day(1, [_nightAssignment]),
        _day(2, [_dayAssignment]),
      ]);

      final result = engine.validateEmployee(_employee, schedule);

      expect(result.warnings.single.ruleId, 'minimum-rest-hours');
    });

    test('registers and removes reusable rules', () {
      final engine = RuleEngine();
      engine.registerRule(const WeekendRule());

      expect(engine.rules, hasLength(1));
      expect(engine.removeRule('weekend-rule'), isTrue);
      expect(engine.rules, isEmpty);
    });

    test('validates a proposed assignment against its target day', () {
      final engine = RuleEngine(rules: const [DuplicateShiftRule()]);
      final day = _day(1, [_dayAssignment]);

      final result = engine.validateAssignment(_dayAssignment, day: day);

      expect(result.errors.single.ruleId, 'duplicate-shifts');
    });

    test('executes multiple independent rules in one pass', () {
      final engine = RuleEngine(
        rules: const [
          DuplicateShiftRule(),
          MissingRequiredStaffRule(),
          InvalidShiftDurationRule(),
          EmptyAssignmentRule(),
        ],
      );
      final schedule = _schedule([
        _day(1, [_emptyAssignment, _emptyAssignment]),
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.violations.map((violation) => violation.ruleId).toSet(), {
        'duplicate-shifts',
        'missing-required-staff',
        'invalid-shift-duration',
        'empty-assignment',
      });
    });

    test('aggregates errors from every failing rule', () {
      final engine = RuleEngine(
        rules: const [
          DuplicateShiftRule(),
          MissingRequiredStaffRule(),
          InvalidShiftDurationRule(),
        ],
      );
      final schedule = _schedule([
        _day(1, [_emptyAssignment, _emptyAssignment]),
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.passed, isFalse);
      expect(result.errors, hasLength(5));
      expect(result.errors.map((violation) => violation.ruleId), [
        'duplicate-shifts',
        'missing-required-staff',
        'missing-required-staff',
        'invalid-shift-duration',
        'invalid-shift-duration',
      ]);
    });

    test('aggregates warnings without failing validation', () {
      final engine = RuleEngine(
        rules: const [EmptyAssignmentRule(), WeekendRule()],
      );
      final schedule = _schedule([
        _day(4, [_emptyAssignment]), // Saturday, 4 July 2026.
      ]);

      final result = engine.validateSchedule(schedule);

      expect(result.passed, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, hasLength(2));
      expect(result.warnings.map((violation) => violation.ruleId), [
        'empty-assignment',
        'weekend-rule',
      ]);
    });

    test('preserves registered rule ordering deterministically', () {
      final engine = RuleEngine(
        rules: const [
          EmptyAssignmentRule(),
          InvalidShiftDurationRule(),
          MissingRequiredStaffRule(),
        ],
      );
      final schedule = _schedule([
        _day(1, [_emptyAssignment]),
      ]);

      final first = engine.validateSchedule(schedule);
      final second = engine.validateSchedule(schedule);

      expect(first.violations.map((violation) => violation.ruleId), [
        'empty-assignment',
        'invalid-shift-duration',
        'missing-required-staff',
      ]);
      expect(
        second.violations.map((violation) => violation.ruleId),
        first.violations.map((violation) => violation.ruleId),
      );
    });
  });
}

const _department = Department(id: 'er', code: 'ER', name: 'Emergency');
const _employee = Employee(
  id: 'e1',
  employeeCode: '001',
  firstName: 'Anan',
  lastName: 'Sukjai',
  nickname: 'Nan',
  department: _department,
  position: 'Nurse',
);
const _dayShift = ShiftType(
  id: 'day',
  code: 'D',
  name: 'Day',
  color: 0xFF1565C0,
  startTime: Duration(hours: 8),
  endTime: Duration(hours: 16),
  workingHours: 8,
);
const _nightShift = ShiftType(
  id: 'night',
  code: 'N',
  name: 'Night',
  color: 0xFF4527A0,
  startTime: Duration(hours: 20),
  endTime: Duration(hours: 8),
  workingHours: 12,
);
const _dayAssignment = ShiftAssignment(employee: _employee, shift: _dayShift);
const _nightAssignment = ShiftAssignment(
  employee: _employee,
  shift: _nightShift,
);
const _emptyEmployee = Employee(
  id: '',
  employeeCode: '',
  firstName: '',
  lastName: '',
  nickname: '',
  department: _department,
  position: '',
);
const _emptyShift = ShiftType(
  id: '',
  code: '',
  name: '',
  color: 0xFF000000,
  startTime: Duration.zero,
  endTime: Duration.zero,
  workingHours: 0,
);
const _emptyAssignment = ShiftAssignment(
  employee: _emptyEmployee,
  shift: _emptyShift,
);

ScheduleDay _day(int day, List<ShiftAssignment> assignments) =>
    ScheduleDay(date: DateTime(2026, 7, day), assignments: assignments);

Schedule _schedule(List<ScheduleDay> days) => Schedule(
  id: 'schedule',
  name: 'July schedule',
  months: [ScheduleMonth(month: DateTime(2026, 7), days: days)],
);
