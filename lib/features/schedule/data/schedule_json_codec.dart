import 'dart:convert';

import '../../../domain/entities/department.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/schedule_month.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../../../domain/entities/shift_type.dart';

/// Indicates that a persisted schedule payload does not match the schema.
class ScheduleCodecException extends FormatException {
  /// Creates a controlled schedule decoding or encoding failure.
  const ScheduleCodecException(super.message);
}

/// Indicates that a payload uses an unsupported schedule schema version.
final class UnsupportedScheduleVersionException extends ScheduleCodecException {
  /// Creates an unsupported-version failure.
  const UnsupportedScheduleVersionException(super.message);
}

/// Encodes and decodes the complete canonical [Schedule] aggregate.
class ScheduleJsonCodec {
  /// Creates the versioned canonical schedule codec.
  const ScheduleJsonCodec();

  /// Current durable schema version.
  static const schemaVersion = 1;

  /// Stable payload type discriminator.
  static const format = 'shift-tools.canonical-schedule';

  /// Encodes [schedule] using schema version 1.
  String encode(Schedule schedule) {
    final departments = <String, Department>{};
    final employees = <String, Employee>{};
    final shifts = <String, ShiftType>{};

    for (final month in schedule.months) {
      for (final day in month.days) {
        for (final assignment in day.assignments) {
          _addDepartment(departments, assignment.employee.department);
          _addEmployee(employees, assignment.employee);
          _addShift(shifts, assignment.shift);
        }
      }
    }

    final departmentValues = departments.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final employeeValues = employees.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final shiftValues = shifts.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));

    return jsonEncode(<String, Object?>{
      'format': format,
      'version': schemaVersion,
      'schedule': <String, Object?>{
        'id': schedule.id,
        'name': schedule.name,
        'departments': [
          for (final department in departmentValues)
            <String, Object?>{
              'id': department.id,
              'code': department.code,
              'name': department.name,
            },
        ],
        'employees': [
          for (final employee in employeeValues)
            <String, Object?>{
              'id': employee.id,
              'employeeCode': employee.employeeCode,
              'firstName': employee.firstName,
              'lastName': employee.lastName,
              'nickname': employee.nickname,
              'departmentId': employee.department.id,
              'position': employee.position,
              'active': employee.active,
            },
        ],
        'shiftTypes': [
          for (final shift in shiftValues)
            <String, Object?>{
              'id': shift.id,
              'code': shift.code,
              'name': shift.name,
              'color': shift.color,
              'startTimeMicroseconds': shift.startTime.inMicroseconds,
              'endTimeMicroseconds': shift.endTime.inMicroseconds,
              'workingHours': shift.workingHours,
            },
        ],
        'months': [
          for (final month in schedule.months)
            <String, Object?>{
              'month': month.month.toIso8601String(),
              'days': [
                for (final day in month.days)
                  <String, Object?>{
                    'date': day.date.toIso8601String(),
                    'holidayName': day.holidayName,
                    'assignments': [
                      for (final assignment in day.assignments)
                        <String, Object?>{
                          'employeeId': assignment.employee.id,
                          'shiftTypeId': assignment.shift.id,
                          'remark': assignment.remark,
                          'location': assignment.location,
                        },
                    ],
                  },
              ],
            },
        ],
      },
    });
  }

  /// Decodes one schema-versioned canonical schedule.
  Schedule decode(String source) {
    final root = _map(jsonDecode(source), r'$');
    final payloadFormat = _string(root, 'format', r'$.format');
    if (payloadFormat != format) {
      throw ScheduleCodecException(
        'Unsupported schedule format "$payloadFormat".',
      );
    }
    final version = _int(root, 'version', r'$.version');
    if (version != schemaVersion) {
      throw UnsupportedScheduleVersionException(
        'Unsupported schedule schema version $version; '
        'expected $schemaVersion.',
      );
    }

    final json = _map(root['schedule'], r'$.schedule');
    final departments = <String, Department>{};
    for (final entry in _list(json, 'departments', r'$.schedule.departments')) {
      final value = _map(entry, r'$.schedule.departments[]');
      final department = Department(
        id: _string(value, 'id', r'$.schedule.departments[].id'),
        code: _string(value, 'code', r'$.schedule.departments[].code'),
        name: _string(value, 'name', r'$.schedule.departments[].name'),
      );
      if (departments.containsKey(department.id)) {
        throw ScheduleCodecException(
          'Duplicate department id "${department.id}".',
        );
      }
      departments[department.id] = department;
    }

    final employees = <String, Employee>{};
    for (final entry in _list(json, 'employees', r'$.schedule.employees')) {
      final value = _map(entry, r'$.schedule.employees[]');
      final departmentId = _string(
        value,
        'departmentId',
        r'$.schedule.employees[].departmentId',
      );
      final department = departments[departmentId];
      if (department == null) {
        throw ScheduleCodecException(
          'Employee references unknown department "$departmentId".',
        );
      }
      final employee = Employee(
        id: _string(value, 'id', r'$.schedule.employees[].id'),
        employeeCode: _string(
          value,
          'employeeCode',
          r'$.schedule.employees[].employeeCode',
        ),
        firstName: _string(
          value,
          'firstName',
          r'$.schedule.employees[].firstName',
        ),
        lastName: _string(
          value,
          'lastName',
          r'$.schedule.employees[].lastName',
        ),
        nickname: _string(
          value,
          'nickname',
          r'$.schedule.employees[].nickname',
        ),
        department: department,
        position: _string(
          value,
          'position',
          r'$.schedule.employees[].position',
        ),
        active: _bool(value, 'active', r'$.schedule.employees[].active'),
      );
      if (employees.containsKey(employee.id)) {
        throw ScheduleCodecException('Duplicate employee id "${employee.id}".');
      }
      employees[employee.id] = employee;
    }

    final shifts = <String, ShiftType>{};
    for (final entry in _list(json, 'shiftTypes', r'$.schedule.shiftTypes')) {
      final value = _map(entry, r'$.schedule.shiftTypes[]');
      final shift = ShiftType(
        id: _string(value, 'id', r'$.schedule.shiftTypes[].id'),
        code: _string(value, 'code', r'$.schedule.shiftTypes[].code'),
        name: _string(value, 'name', r'$.schedule.shiftTypes[].name'),
        color: _int(value, 'color', r'$.schedule.shiftTypes[].color'),
        startTime: Duration(
          microseconds: _int(
            value,
            'startTimeMicroseconds',
            r'$.schedule.shiftTypes[].startTimeMicroseconds',
          ),
        ),
        endTime: Duration(
          microseconds: _int(
            value,
            'endTimeMicroseconds',
            r'$.schedule.shiftTypes[].endTimeMicroseconds',
          ),
        ),
        workingHours: _double(
          value,
          'workingHours',
          r'$.schedule.shiftTypes[].workingHours',
        ),
      );
      if (shifts.containsKey(shift.id)) {
        throw ScheduleCodecException('Duplicate shift type id "${shift.id}".');
      }
      shifts[shift.id] = shift;
    }

    final months = <ScheduleMonth>[];
    for (final entry in _list(json, 'months', r'$.schedule.months')) {
      final monthJson = _map(entry, r'$.schedule.months[]');
      final days = <ScheduleDay>[];
      for (final dayEntry in _list(
        monthJson,
        'days',
        r'$.schedule.months[].days',
      )) {
        final dayJson = _map(dayEntry, r'$.schedule.months[].days[]');
        final assignments = <ShiftAssignment>[];
        for (final assignmentEntry in _list(
          dayJson,
          'assignments',
          r'$.schedule.months[].days[].assignments',
        )) {
          final assignmentJson = _map(
            assignmentEntry,
            r'$.schedule.months[].days[].assignments[]',
          );
          final employeeId = _string(
            assignmentJson,
            'employeeId',
            r'$.schedule.months[].days[].assignments[].employeeId',
          );
          final shiftId = _string(
            assignmentJson,
            'shiftTypeId',
            r'$.schedule.months[].days[].assignments[].shiftTypeId',
          );
          final employee = employees[employeeId];
          final shift = shifts[shiftId];
          if (employee == null) {
            throw ScheduleCodecException(
              'Assignment references unknown employee "$employeeId".',
            );
          }
          if (shift == null) {
            throw ScheduleCodecException(
              'Assignment references unknown shift type "$shiftId".',
            );
          }
          assignments.add(
            ShiftAssignment(
              employee: employee,
              shift: shift,
              remark: _optionalString(assignmentJson, 'remark'),
              location: _optionalString(assignmentJson, 'location'),
            ),
          );
        }
        days.add(
          ScheduleDay(
            date: _date(dayJson, 'date', r'$.schedule.months[].days[].date'),
            assignments: assignments,
            holidayName: _optionalString(dayJson, 'holidayName'),
          ),
        );
      }
      months.add(
        ScheduleMonth(
          month: _date(monthJson, 'month', r'$.schedule.months[].month'),
          days: days,
        ),
      );
    }

    return Schedule(
      id: _string(json, 'id', r'$.schedule.id'),
      name: _string(json, 'name', r'$.schedule.name'),
      months: months,
    );
  }

  void _addDepartment(Map<String, Department> values, Department department) {
    final existing = values[department.id];
    if (existing != null && existing != department) {
      throw ScheduleCodecException(
        'Conflicting department values for id "${department.id}".',
      );
    }
    values[department.id] = department;
  }

  void _addEmployee(Map<String, Employee> values, Employee employee) {
    final existing = values[employee.id];
    if (existing != null && !_sameEmployee(existing, employee)) {
      throw ScheduleCodecException(
        'Conflicting employee values for id "${employee.id}".',
      );
    }
    values[employee.id] = employee;
  }

  void _addShift(Map<String, ShiftType> values, ShiftType shift) {
    final existing = values[shift.id];
    if (existing != null && !_sameShift(existing, shift)) {
      throw ScheduleCodecException(
        'Conflicting shift values for id "${shift.id}".',
      );
    }
    values[shift.id] = shift;
  }

  bool _sameEmployee(Employee left, Employee right) =>
      left.employeeCode == right.employeeCode &&
      left.firstName == right.firstName &&
      left.lastName == right.lastName &&
      left.nickname == right.nickname &&
      left.department == right.department &&
      left.position == right.position &&
      left.active == right.active;

  bool _sameShift(ShiftType left, ShiftType right) =>
      left.code == right.code &&
      left.name == right.name &&
      left.color == right.color &&
      left.startTime == right.startTime &&
      left.endTime == right.endTime &&
      left.workingHours == right.workingHours;
}

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) {
    throw ScheduleCodecException('$path must be a JSON object.');
  }
  try {
    return Map<String, Object?>.from(value);
  } on Object {
    throw ScheduleCodecException('$path must use string keys.');
  }
}

List<Object?> _list(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! List) {
    throw ScheduleCodecException('$path must be a JSON list.');
  }
  return List<Object?>.from(value);
}

String _string(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! String) {
    throw ScheduleCodecException('$path must be a string.');
  }
  return value;
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw ScheduleCodecException('$key must be a string or null.');
  }
  return value;
}

int _int(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! num || value.toInt() != value) {
    throw ScheduleCodecException('$path must be an integer.');
  }
  return value.toInt();
}

double _double(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! num) {
    throw ScheduleCodecException('$path must be a number.');
  }
  return value.toDouble();
}

bool _bool(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! bool) {
    throw ScheduleCodecException('$path must be a boolean.');
  }
  return value;
}

DateTime _date(Map<String, Object?> json, String key, String path) {
  final source = _string(json, key, path);
  final value = DateTime.tryParse(source);
  if (value == null) {
    throw ScheduleCodecException('$path must be an ISO-8601 date.');
  }
  return value;
}
