import '../../../domain/entities/schedule.dart';
import '../domain/department.dart';
import '../domain/employee.dart';
import '../domain/schedule_month.dart';
import '../domain/schedule_statistics.dart';
import '../domain/shift.dart';
import '../domain/shift_assignment.dart';

class ScheduleService {
  ScheduleService({
    Schedule? schedule,
    List<Employee> employees = const [],
    List<Department> departments = const [],
    List<Shift> shifts = const [],
  }) : _schedule = schedule ?? Schedule(id: 'in-memory', name: 'Schedule'),
       _employees = _catalog(
         employees,
         schedule,
         (assignment) => assignment.employee,
         (employee) => employee.id,
       ),
       _departments = _catalog(
         departments,
         schedule,
         (assignment) => assignment.employee.department,
         (department) => department.id,
       ),
       _shifts = _catalog(
         shifts,
         schedule,
         (assignment) => assignment.shift,
         (shift) => shift.id,
       );

  Schedule _schedule;
  final List<Employee> _employees;
  final List<Department> _departments;
  final List<Shift> _shifts;

  Schedule get schedule => _schedule;
  List<Employee> get employees => List.unmodifiable(_employees);
  List<Department> get departments => List.unmodifiable(_departments);
  List<Shift> get shifts => List.unmodifiable(_shifts);

  /// Replaces the in-memory aggregate with a restored canonical schedule.
  void replaceSchedule(Schedule schedule) {
    _schedule = schedule;
    _employees
      ..clear()
      ..addAll(
        _catalog(
          const [],
          schedule,
          (assignment) => assignment.employee,
          (employee) => employee.id,
        ),
      );
    _departments
      ..clear()
      ..addAll(
        _catalog(
          const [],
          schedule,
          (assignment) => assignment.employee.department,
          (department) => department.id,
        ),
      );
    _shifts
      ..clear()
      ..addAll(
        _catalog(
          const [],
          schedule,
          (assignment) => assignment.shift,
          (shift) => shift.id,
        ),
      );
  }

  ScheduleMonth createSchedule(DateTime month) {
    final existing = _schedule.month(month);
    if (existing != null) return existing;
    final created = ScheduleMonth.empty(month);
    _schedule = _schedule.replaceMonth(created);
    return created;
  }

  ScheduleMonth updateAssignment({
    required DateTime date,
    required ShiftAssignment assignment,
  }) {
    if (!_employees.any((employee) => employee.id == assignment.employee.id)) {
      _employees.add(assignment.employee);
    }
    if (!_departments.any(
      (department) => department.id == assignment.employee.department.id,
    )) {
      _departments.add(assignment.employee.department);
    }
    if (!_shifts.any((shift) => shift.id == assignment.shift.id)) {
      _shifts.add(assignment.shift);
    }
    final schedule = createSchedule(date);
    final day = schedule.day(date)!;
    final assignments = List<ShiftAssignment>.of(day.assignments);
    final existingIndex = assignments.indexWhere(
      (item) =>
          item.employee.id == assignment.employee.id &&
          item.shift.id == assignment.shift.id,
    );
    if (existingIndex == -1) {
      assignments.add(assignment);
    } else {
      assignments[existingIndex] = assignment;
    }
    final updated = schedule.replaceDay(day.copyWith(assignments: assignments));
    _schedule = _schedule.replaceMonth(updated);
    return updated;
  }

  ScheduleMonth deleteAssignment({
    required DateTime date,
    required String employeeId,
    required String shiftId,
  }) {
    final schedule = createSchedule(date);
    final day = schedule.day(date)!;
    final updated = schedule.replaceDay(
      day.copyWith(
        assignments: day.assignments
            .where(
              (item) =>
                  item.employee.id != employeeId || item.shift.id != shiftId,
            )
            .toList(),
      ),
    );
    _schedule = _schedule.replaceMonth(updated);
    return updated;
  }

  List<Employee> searchEmployee(String query) {
    return _employees
        .where((employee) => employee.active && employee.matches(query))
        .toList(growable: false);
  }

  List<Shift> searchShift(String query) {
    return _shifts
        .where((shift) => shift.matches(query))
        .toList(growable: false);
  }

  ScheduleStatistics monthlyStatistics(
    ScheduleMonth schedule, {
    String? employeeId,
    String? departmentId,
    String? shiftId,
    DateTime? date,
    String staffNameQuery = '',
    String positionQuery = '',
  }) {
    var total = 0;
    var nights = 0;
    var holidays = 0;
    var hours = 0.0;

    for (final day in schedule.days) {
      if (date != null && !_isSameDay(day.date, date)) {
        continue;
      }
      for (final assignment in day.assignments) {
        if (!_matchesFilters(
          assignment,
          employeeId: employeeId,
          departmentId: departmentId,
          shiftId: shiftId,
          staffNameQuery: staffNameQuery,
          positionQuery: positionQuery,
        )) {
          continue;
        }
        total++;
        hours += assignment.shift.workingHours;
        if (assignment.shift.isNightShift) {
          nights++;
        }
        if (day.isHoliday) {
          holidays++;
        }
      }
    }

    return ScheduleStatistics(
      totalShifts: total,
      nightShifts: nights,
      holidayShifts: holidays,
      workingHours: hours,
    );
  }

  bool _matchesFilters(
    ShiftAssignment assignment, {
    String? employeeId,
    String? departmentId,
    String? shiftId,
    String staffNameQuery = '',
    String positionQuery = '',
  }) {
    return (employeeId == null || assignment.employee.id == employeeId) &&
        (departmentId == null ||
            assignment.employee.department.id == departmentId) &&
        (shiftId == null || assignment.shift.id == shiftId) &&
        _matchesStaffName(assignment.employee, staffNameQuery) &&
        _matchesPosition(assignment.employee, positionQuery);
  }

  bool _matchesStaffName(Employee employee, String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        employee.employeeCode.toLowerCase().contains(normalized) ||
        employee.firstName.toLowerCase().contains(normalized) ||
        employee.lastName.toLowerCase().contains(normalized) ||
        employee.nickname.toLowerCase().contains(normalized) ||
        employee.fullName.toLowerCase().contains(normalized);
  }

  bool _matchesPosition(Employee employee, String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty || employee.position.toLowerCase() == normalized;
  }

  bool _isSameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

List<T> _catalog<T>(
  List<T> explicitValues,
  Schedule? schedule,
  T Function(ShiftAssignment assignment) select,
  String Function(T value) id,
) {
  if (explicitValues.isNotEmpty || schedule == null) {
    return List.of(explicitValues);
  }
  final values = <String, T>{};
  for (final month in schedule.months) {
    for (final day in month.days) {
      for (final assignment in day.assignments) {
        final value = select(assignment);
        values[id(value)] = value;
      }
    }
  }
  return values.values.toList();
}
