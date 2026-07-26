import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/domain/entities/department.dart';
import 'package:phakphum_calendar/domain/entities/employee.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/domain/entities/schedule_day.dart';
import 'package:phakphum_calendar/domain/entities/schedule_month.dart';
import 'package:phakphum_calendar/domain/entities/shift_assignment.dart';
import 'package:phakphum_calendar/domain/entities/shift_type.dart';
import 'package:phakphum_calendar/features/schedule_generation/application/conflict_detection_service.dart';
import 'package:phakphum_calendar/features/schedule_generation/application/coverage_checking_service.dart';
import 'package:phakphum_calendar/features/schedule_generation/application/schedule_generator.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/coverage_requirement.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/department_capacity.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/employee_availability.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/generation_request.dart';
import 'package:phakphum_calendar/features/schedule_generation/domain/schedule_conflict.dart';

void main() {
  group('ScheduleGenerator', () {
    test('creates a manual assignment', () {
      const generator = ScheduleGenerator();

      final result = generator.manualAssignment(
        schedule: _emptySchedule(),
        date: _date,
        assignment: const ShiftAssignment(
          employee: _employeeOne,
          shift: _dayShift,
        ),
      );

      expect(result.assignmentsCreated, 1);
      expect(result.conflicts, isEmpty);
      expect(
        result.schedule.month(_date)!.day(_date)!.assignments,
        hasLength(1),
      );
    });

    test('rejects a manual assignment for an unavailable employee', () {
      const generator = ScheduleGenerator();

      final result = generator.manualAssignment(
        schedule: _emptySchedule(),
        date: _date,
        assignment: const ShiftAssignment(
          employee: _employeeOne,
          shift: _dayShift,
        ),
        availability: [
          EmployeeAvailability(
            employeeId: _employeeOne.id,
            date: _date,
            available: false,
          ),
        ],
      );

      expect(result.assignmentsCreated, 0);
      expect(
        result.conflicts.single.type,
        ScheduleConflictType.unavailableEmployee,
      );
    });

    test('auto assigns eligible employees to meet coverage', () {
      const generator = ScheduleGenerator();
      final requirement = CoverageRequirement(
        id: 'coverage-1',
        date: _date,
        departmentId: _department.id,
        shiftTypeId: _dayShift.id,
        requiredEmployees: 2,
      );
      final request = GenerationRequest(
        schedule: _emptySchedule(),
        month: _date,
        employees: const [_employeeOne, _employeeTwo],
        shiftTypes: const [_dayShift],
        coverageRequirements: [requirement],
      );

      final result = generator.autoAssign(request);

      expect(result.assignmentsCreated, 2);
      expect(result.uncoveredRequirements, isEmpty);
      expect(result.completed, isTrue);
      expect(
        result.schedule.month(_date)!.day(_date)!.assignments,
        hasLength(2),
      );
    });

    test('reports insufficient coverage when capacity is reached', () {
      const generator = ScheduleGenerator();
      final requirement = CoverageRequirement(
        id: 'coverage-1',
        date: _date,
        departmentId: _department.id,
        shiftTypeId: _dayShift.id,
        requiredEmployees: 2,
      );
      final request = GenerationRequest(
        schedule: _emptySchedule(),
        month: _date,
        employees: const [_employeeOne, _employeeTwo],
        shiftTypes: const [_dayShift],
        coverageRequirements: [requirement],
        departmentCapacities: [
          DepartmentCapacity(
            departmentId: _department.id,
            date: _date,
            maximumAssignments: 1,
          ),
        ],
      );

      final result = generator.autoAssign(request);

      expect(result.assignmentsCreated, 1);
      expect(result.uncoveredRequirements, [requirement]);
      expect(
        result.conflicts.single.type,
        ScheduleConflictType.insufficientCoverage,
      );
    });
  });

  test('conflict detection finds duplicate assignments', () {
    const assignment = ShiftAssignment(
      employee: _employeeOne,
      shift: _dayShift,
    );
    final schedule = Schedule(
      id: 'schedule',
      name: 'Schedule',
      months: [
        ScheduleMonth(
          month: _date,
          days: [
            ScheduleDay(
              date: _date,
              assignments: const [assignment, assignment],
            ),
          ],
        ),
      ],
    );

    final conflicts = const ConflictDetectionService().detectScheduleConflicts(
      schedule,
    );

    expect(conflicts.single.type, ScheduleConflictType.duplicateAssignment);
  });

  test('coverage checking reports unmet requirements', () {
    final requirement = CoverageRequirement(
      id: 'coverage',
      date: _date,
      departmentId: _department.id,
      shiftTypeId: _dayShift.id,
      requiredEmployees: 1,
    );

    final uncovered = const CoverageCheckingService().uncovered(
      _emptySchedule(),
      [requirement],
    );

    expect(uncovered, [requirement]);
  });
}

final _date = DateTime(2026, 7, 6);
const _department = Department(id: 'er', code: 'ER', name: 'Emergency');
const _employeeOne = Employee(
  id: 'e1',
  employeeCode: '001',
  firstName: 'Anan',
  lastName: 'Sukjai',
  nickname: 'Nan',
  department: _department,
  position: 'Nurse',
);
const _employeeTwo = Employee(
  id: 'e2',
  employeeCode: '002',
  firstName: 'Mali',
  lastName: 'Dee',
  nickname: 'Mai',
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

Schedule _emptySchedule() => Schedule(
  id: 'schedule',
  name: 'Schedule',
  months: [ScheduleMonth.empty(_date)],
);
