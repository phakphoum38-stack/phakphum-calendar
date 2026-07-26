import 'package:phakphum_calendar/domain/entities/department.dart';
import 'package:phakphum_calendar/domain/entities/employee.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/domain/entities/schedule_day.dart';
import 'package:phakphum_calendar/domain/entities/schedule_month.dart';
import 'package:phakphum_calendar/domain/entities/shift_assignment.dart';
import 'package:phakphum_calendar/domain/entities/shift_type.dart';

Schedule canonicalScheduleFixture({
  String id = 'schedule-1',
  String name = 'July and August',
}) {
  const department = Department(id: 'er', code: 'ER', name: 'Emergency');
  const employee = Employee(
    id: 'employee-1',
    employeeCode: 'E001',
    firstName: 'Anan',
    lastName: 'Sukjai',
    nickname: 'Nan',
    department: department,
    position: 'Nurse',
  );
  const shift = ShiftType(
    id: 'night',
    code: 'N',
    name: 'Night',
    color: 0xFF4527A0,
    startTime: Duration(hours: 20),
    endTime: Duration(hours: 8),
    workingHours: 12,
  );
  const firstAssignment = ShiftAssignment(
    employee: employee,
    shift: shift,
    location: 'Ward A',
    remark: 'Charge',
  );
  const secondAssignment = ShiftAssignment(
    employee: employee,
    shift: shift,
    location: 'Ward B',
    remark: 'Training',
  );

  return Schedule(
    id: id,
    name: name,
    months: [
      ScheduleMonth(
        month: DateTime(2026, 7),
        days: [
          ScheduleDay(
            date: DateTime(2026, 7, 24),
            assignments: const [firstAssignment],
          ),
          ScheduleDay(
            date: DateTime(2026, 7, 25),
            assignments: const [secondAssignment],
            holidayName: 'Hospital holiday',
          ),
          ScheduleDay(date: DateTime(2026, 7, 26)),
        ],
      ),
      ScheduleMonth.empty(DateTime(2026, 8)),
    ],
  );
}

List<String> canonicalScheduleValues(Schedule schedule) {
  return [
    schedule.id,
    schedule.name,
    for (final month in schedule.months) ...[
      month.month.toIso8601String(),
      for (final day in month.days) ...[
        day.date.toIso8601String(),
        day.holidayName ?? '',
        for (final assignment in day.assignments) ...[
          assignment.employee.id,
          assignment.employee.employeeCode,
          assignment.employee.firstName,
          assignment.employee.lastName,
          assignment.employee.nickname,
          assignment.employee.department.id,
          assignment.employee.department.code,
          assignment.employee.department.name,
          assignment.employee.position,
          '${assignment.employee.active}',
          assignment.shift.id,
          assignment.shift.code,
          assignment.shift.name,
          '${assignment.shift.color}',
          '${assignment.shift.startTime.inMicroseconds}',
          '${assignment.shift.endTime.inMicroseconds}',
          '${assignment.shift.workingHours}',
          assignment.location ?? '',
          assignment.remark ?? '',
        ],
      ],
    ],
  ];
}
