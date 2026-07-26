import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/result/result.dart';
import 'package:phakphum_calendar/domain/entities/department.dart';
import 'package:phakphum_calendar/domain/entities/employee.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/domain/entities/schedule_month.dart';
import 'package:phakphum_calendar/domain/entities/shift_assignment.dart';
import 'package:phakphum_calendar/domain/entities/shift_type.dart';
import 'package:phakphum_calendar/features/schedule/domain/shift.dart'
    as schedule_feature;

void main() {
  test('result folds success and typed failures', () {
    const Result<int> success = Success(42);
    const Result<int> failure = ValidationFailure(
      'Invalid employee',
      fieldErrors: {'employee': 'Required'},
    );

    expect(success.fold(onSuccess: (value) => value, onFailure: (_) => -1), 42);
    expect(
      failure.fold(
        onSuccess: (value) => '$value',
        onFailure: (error) => error.message,
      ),
      'Invalid employee',
    );
  });

  test('schedule aggregate owns canonical domain months', () {
    final month = ScheduleMonth.empty(DateTime(2026, 7));
    final schedule = Schedule(id: 'main', name: 'Main', months: [month]);

    expect(schedule.month(DateTime(2026, 7)), same(month));
    expect(schedule.month(DateTime(2026, 8)), isNull);
  });

  test('schedule feature shift remains a compatible ShiftType alias', () {
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
    const schedule_feature.Shift shift = schedule_feature.Shift(
      id: 'day',
      code: 'D',
      name: 'Day',
      color: 0xFF1565C0,
      startTime: Duration(hours: 8),
      endTime: Duration(hours: 16),
      workingHours: 8,
    );
    const assignment = ShiftAssignment(employee: employee, shift: shift);

    expect(shift, isA<ShiftType>());
    expect(assignment.shift, same(shift));
  });
}
