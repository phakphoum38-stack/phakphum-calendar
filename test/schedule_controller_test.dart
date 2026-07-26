import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/schedule/data/schedule_service.dart';
import 'package:phakphum_calendar/features/schedule/domain/department.dart';
import 'package:phakphum_calendar/features/schedule/domain/employee.dart';
import 'package:phakphum_calendar/features/schedule/domain/shift.dart';
import 'package:phakphum_calendar/features/schedule/domain/shift_assignment.dart';
import 'package:phakphum_calendar/features/schedule/presentation/controllers/schedule_controller.dart';

void main() {
  const department = Department(id: 'icu', code: 'ICU', name: 'ICU');
  const employee = Employee(
    id: 'employee',
    employeeCode: 'E01',
    firstName: 'Mali',
    lastName: 'Dee',
    nickname: 'Mai',
    department: department,
    position: 'Nurse',
  );
  const shift = Shift(
    id: 'morning',
    code: 'M',
    name: 'Morning',
    color: 0xFF00897B,
    startTime: Duration(hours: 8),
    endTime: Duration(hours: 16),
    workingHours: 8,
  );
  const physician = Employee(
    id: 'physician',
    employeeCode: 'E02',
    firstName: 'Anan',
    lastName: 'Sukjai',
    nickname: 'Nan',
    department: department,
    position: 'Physician',
  );
  const nightShift = Shift(
    id: 'night',
    code: 'N',
    name: 'Night',
    color: 0xFF4527A0,
    startTime: Duration(hours: 20),
    endTime: Duration(hours: 8),
    workingHours: 12,
  );

  test('navigates months and filters visible assignments', () {
    final controller = ScheduleController(
      initialMonth: DateTime(2026, 7),
      service: ScheduleService(
        departments: const [department],
        employees: const [employee],
        shifts: const [shift],
      ),
    );
    addTearDown(controller.dispose);

    controller.updateAssignment(
      DateTime(2026, 7, 10),
      const ShiftAssignment(employee: employee, shift: shift),
    );
    controller.filterEmployee(employee.id);
    controller.filterDepartment(department.id);
    controller.filterShift(shift.id);
    controller.filterDate(DateTime(2026, 7, 10));

    expect(controller.visibleDays, hasLength(1));
    expect(
      controller.assignmentsFor(controller.visibleDays.single),
      hasLength(1),
    );
    expect(controller.statistics.totalShifts, 1);

    controller.nextMonth();
    expect(controller.currentMonth, DateTime(2026, 8));
    expect(controller.selectedDate, isNull);

    controller.previousMonth();
    expect(controller.currentMonth, DateTime(2026, 7));
  });

  test('filters assignments by staff name', () {
    final controller = _filterController(
      employees: const [employee, physician],
      shifts: const [shift, nightShift],
      assignments: const [
        ShiftAssignment(employee: employee, shift: shift),
        ShiftAssignment(employee: physician, shift: nightShift),
      ],
    );

    controller.filterStaffName('mali');

    expect(_selectedAssignments(controller), [
      const ShiftAssignment(employee: employee, shift: shift),
    ]);
  });

  test('filters assignments by role or position', () {
    final controller = _filterController(
      employees: const [employee, physician],
      shifts: const [shift, nightShift],
      assignments: const [
        ShiftAssignment(employee: employee, shift: shift),
        ShiftAssignment(employee: physician, shift: nightShift),
      ],
    );

    controller.filterPosition('Physician');

    expect(_selectedAssignments(controller), [
      const ShiftAssignment(employee: physician, shift: nightShift),
    ]);
  });

  test('filters assignments by shift type', () {
    final controller = _filterController(
      employees: const [employee, physician],
      shifts: const [shift, nightShift],
      assignments: const [
        ShiftAssignment(employee: employee, shift: shift),
        ShiftAssignment(employee: physician, shift: nightShift),
      ],
    );

    controller.filterShift(nightShift.id);

    expect(_selectedAssignments(controller), [
      const ShiftAssignment(employee: physician, shift: nightShift),
    ]);
  });

  test('combines staff, role, and shift filters', () {
    final controller = _filterController(
      employees: const [employee, physician],
      shifts: const [shift, nightShift],
      assignments: const [
        ShiftAssignment(employee: employee, shift: shift),
        ShiftAssignment(employee: physician, shift: nightShift),
      ],
    );

    controller
      ..filterStaffName('nan')
      ..filterPosition('Physician')
      ..filterShift(nightShift.id);

    expect(_selectedAssignments(controller), [
      const ShiftAssignment(employee: physician, shift: nightShift),
    ]);
    expect(controller.statistics.totalShifts, 1);
    expect(controller.activeFilterLabels, hasLength(3));
  });

  test('clearing filters restores every assignment', () {
    final controller = _filterController(
      employees: const [employee, physician],
      shifts: const [shift, nightShift],
      assignments: const [
        ShiftAssignment(employee: employee, shift: shift),
        ShiftAssignment(employee: physician, shift: nightShift),
      ],
    );
    controller
      ..filterStaffName('missing')
      ..filterPosition('Physician')
      ..filterShift(nightShift.id);
    expect(_selectedAssignments(controller), isEmpty);

    controller.clearFilters();

    expect(_selectedAssignments(controller), hasLength(2));
    expect(controller.hasActiveFilters, isFalse);
    expect(controller.staffNameQuery, isEmpty);
    expect(controller.positionQuery, isEmpty);
  });
}

ScheduleController _filterController({
  required List<Employee> employees,
  required List<Shift> shifts,
  required List<ShiftAssignment> assignments,
}) {
  final controller = ScheduleController(
    initialMonth: DateTime(2026, 7),
    service: ScheduleService(employees: employees, shifts: shifts),
  );
  addTearDown(controller.dispose);
  for (final assignment in assignments) {
    controller.updateAssignment(DateTime(2026, 7, 10), assignment);
  }
  controller.selectDay(DateTime(2026, 7, 10));
  return controller;
}

List<ShiftAssignment> _selectedAssignments(ScheduleController controller) {
  final day = controller.schedule.day(DateTime(2026, 7, 10))!;
  return controller.assignmentsFor(day);
}
