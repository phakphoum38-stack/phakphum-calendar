import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/schedule/data/schedule_service.dart';
import 'package:phakphum_calendar/features/schedule/domain/department.dart';
import 'package:phakphum_calendar/features/schedule/domain/employee.dart';
import 'package:phakphum_calendar/features/schedule/domain/schedule_day.dart';
import 'package:phakphum_calendar/features/schedule/domain/schedule_month.dart';
import 'package:phakphum_calendar/features/schedule/domain/shift.dart';
import 'package:phakphum_calendar/features/schedule/domain/shift_assignment.dart';

void main() {
  const department = Department(id: 'er', code: 'ER', name: 'Emergency');
  const employee = Employee(
    id: 'e1',
    employeeCode: '001',
    firstName: 'Anan',
    lastName: 'Sukjai',
    nickname: 'Nan',
    department: department,
    position: 'Nurse',
  );
  const dayShift = Shift(
    id: 'day',
    code: 'D',
    name: 'Day',
    color: 0xFF1565C0,
    startTime: Duration(hours: 8),
    endTime: Duration(hours: 16),
    workingHours: 8,
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

  test('creates a full calendar month and updates assignments', () {
    final service = ScheduleService(
      employees: const [employee],
      departments: const [department],
      shifts: const [dayShift],
    );
    final schedule = service.createSchedule(DateTime(2026, 2));

    expect(schedule.days, hasLength(28));

    final updated = service.updateAssignment(
      date: DateTime(2026, 2, 3),
      assignment: const ShiftAssignment(
        employee: employee,
        shift: dayShift,
        remark: 'Training',
      ),
    );
    expect(updated.day(DateTime(2026, 2, 3))!.assignments, hasLength(1));

    final deleted = service.deleteAssignment(
      date: DateTime(2026, 2, 3),
      employeeId: employee.id,
      shiftId: dayShift.id,
    );
    expect(deleted.day(DateTime(2026, 2, 3))!.assignments, isEmpty);
  });

  test('searches employees and shifts case-insensitively', () {
    final service = ScheduleService(
      employees: const [employee],
      shifts: const [dayShift, nightShift],
    );

    expect(service.searchEmployee('nan'), [employee]);
    expect(service.searchShift('night'), [nightShift]);
  });

  test('calculates monthly shift statistics', () {
    final service = ScheduleService(shifts: const [dayShift, nightShift]);
    service.updateAssignment(
      date: DateTime(2026, 7, 4),
      assignment: const ShiftAssignment(employee: employee, shift: nightShift),
    );
    service.updateAssignment(
      date: DateTime(2026, 7, 6),
      assignment: const ShiftAssignment(employee: employee, shift: dayShift),
    );

    final statistics = service.monthlyStatistics(
      service.createSchedule(DateTime(2026, 7)),
    );

    expect(statistics.totalShifts, 2);
    expect(statistics.nightShifts, 1);
    expect(statistics.holidayShifts, 1);
    expect(statistics.workingHours, 20);
  });

  test('supports named holidays in addition to weekends', () {
    final schedule = ScheduleMonth(
      month: DateTime(2026, 7),
      days: [
        ScheduleDay(date: DateTime(2026, 7, 8), holidayName: 'Company holiday'),
      ],
    );

    expect(schedule.days.single.isHoliday, isTrue);
    expect(schedule.days.single.holidayName, 'Company holiday');
  });
}
