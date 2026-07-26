import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/domain/entities/department.dart';
import 'package:phakphum_calendar/domain/entities/employee.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/domain/entities/schedule_day.dart';
import 'package:phakphum_calendar/domain/entities/schedule_month.dart';
import 'package:phakphum_calendar/domain/entities/shift_assignment.dart';
import 'package:phakphum_calendar/domain/entities/shift_type.dart';
import 'package:phakphum_calendar/features/reports/application/monthly_schedule_report_mapper.dart';
import 'package:phakphum_calendar/features/reports/domain/monthly_report_options.dart';

void main() {
  const mapper = MonthlyScheduleReportMapper();
  final generatedAt = DateTime(2026, 1, 2, 10, 30);

  test('empty Schedule produces a valid zero-statistics month', () {
    final report = mapper.map(
      Schedule(id: 'empty', name: 'Empty'),
      MonthlyReportOptions(month: DateTime(2026, 2), generatedAt: generatedAt),
    );

    expect(report.dates, hasLength(28));
    expect(report.rows, isEmpty);
    expect(report.statistics.employeeCount, 0);
    expect(report.statistics.assignmentCount, 0);
    expect(report.statistics.reliableWorkingHours, isNull);
  });

  test('selects one month and preserves Thai values and multiple shifts', () {
    final schedule = _fixture();
    final report = mapper.map(
      schedule,
      MonthlyReportOptions(month: DateTime(2026, 1), generatedAt: generatedAt),
    );

    expect(report.metadata.scheduleName, 'ตารางเวรโรงพยาบาล');
    expect(report.dates.first.date, DateTime(2026, 1, 1));
    expect(report.dates.last.date, DateTime(2026, 1, 31));
    expect(report.rows.map((row) => row.employeeName), [
      'กมล ชัยดี (ก้อย)',
      'สมชาย ใจดี',
    ]);
    expect(report.rows.first.cells.first.shiftLabels, ['D', 'N']);
    expect(report.rows.first.cells.first.locations, ['หอผู้ป่วย A']);
    expect(report.rows.first.cells.first.notes, ['หัวหน้าเวร', 'อบรม']);
    expect(report.dates.first.holidayName, 'วันขึ้นปีใหม่');
    expect(report.notes, contains(contains('หัวหน้าเวร')));
    expect(schedule.months, hasLength(2));
  });

  test('department filter retains only matching employees and assignments', () {
    final report = mapper.map(
      _fixture(),
      MonthlyReportOptions(
        month: DateTime(2026, 1),
        departmentId: 'er',
        generatedAt: generatedAt,
      ),
    );

    expect(report.rows, hasLength(1));
    expect(report.rows.single.departmentId, 'er');
    expect(report.statistics.assignmentCount, 2);
    expect(report.statistics.assignmentsByDepartment, isEmpty);
  });

  test('statistics and legend are deterministic and omit unreliable hours', () {
    final options = MonthlyReportOptions(
      month: DateTime(2026, 1),
      generatedAt: generatedAt,
    );
    final first = mapper.map(_fixture(), options);
    final second = mapper.map(_fixture(), options);

    expect(first.legend.map((entry) => entry.code), ['D', 'N', 'Z']);
    expect(first.statistics.employeeCount, 2);
    expect(first.statistics.assignmentCount, 3);
    expect(first.statistics.assignmentsByShift, {'D': 1, 'N': 1, 'Z': 1});
    expect(first.statistics.assignmentsByDepartment, {
      'ฉุกเฉิน': 2,
      'รังสีวิทยา': 1,
    });
    expect(first.statistics.reliableWorkingHours, isNull);
    expect(
      first.rows.map((row) => row.employeeId),
      second.rows.map((row) => row.employeeId),
    );
  });
}

Schedule _fixture() {
  const er = Department(id: 'er', code: 'ER', name: 'ฉุกเฉิน');
  const radiology = Department(id: 'rad', code: 'RAD', name: 'รังสีวิทยา');
  const kamon = Employee(
    id: 'e-1',
    employeeCode: '001',
    firstName: 'กมล',
    lastName: 'ชัยดี',
    nickname: 'ก้อย',
    department: er,
    position: 'พยาบาล',
  );
  const somchai = Employee(
    id: 'e-2',
    employeeCode: '002',
    firstName: 'สมชาย',
    lastName: 'ใจดี',
    nickname: '',
    department: radiology,
    position: 'นักรังสีการแพทย์',
  );
  const day = ShiftType(
    id: 'day',
    code: 'D',
    name: 'เวรเช้า',
    color: 0xFF1565C0,
    startTime: Duration(hours: 8),
    endTime: Duration(hours: 16),
    workingHours: 8,
  );
  const night = ShiftType(
    id: 'night',
    code: 'N',
    name: 'เวรดึก',
    color: 0xFF4527A0,
    startTime: Duration(hours: 20),
    endTime: Duration(hours: 8),
    workingHours: 12,
  );
  const unknown = ShiftType(
    id: 'zero',
    code: 'Z',
    name: 'เวรไม่ระบุเวลา',
    color: 0xFF616161,
    startTime: Duration.zero,
    endTime: Duration.zero,
    workingHours: 0,
  );
  final january = ScheduleMonth.empty(DateTime(2026, 1))
      .replaceDay(
        ScheduleDay(
          date: DateTime(2026, 1, 1),
          holidayName: 'วันขึ้นปีใหม่',
          assignments: const [
            ShiftAssignment(
              employee: kamon,
              shift: night,
              location: 'หอผู้ป่วย A',
              remark: 'อบรม',
            ),
            ShiftAssignment(
              employee: kamon,
              shift: day,
              location: 'หอผู้ป่วย A',
              remark: 'หัวหน้าเวร',
            ),
          ],
        ),
      )
      .replaceDay(
        ScheduleDay(
          date: DateTime(2026, 1, 2),
          assignments: const [
            ShiftAssignment(employee: somchai, shift: unknown),
          ],
        ),
      );
  return Schedule(
    id: 'thai-schedule',
    name: 'ตารางเวรโรงพยาบาล',
    months: [january, ScheduleMonth.empty(DateTime(2026, 2))],
  );
}
