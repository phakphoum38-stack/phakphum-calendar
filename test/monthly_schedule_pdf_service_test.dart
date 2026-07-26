import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/result/result.dart';
import 'package:phakphum_calendar/domain/entities/department.dart';
import 'package:phakphum_calendar/domain/entities/employee.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/domain/entities/schedule_day.dart';
import 'package:phakphum_calendar/domain/entities/schedule_month.dart';
import 'package:phakphum_calendar/domain/entities/shift_assignment.dart';
import 'package:phakphum_calendar/domain/entities/shift_type.dart';
import 'package:phakphum_calendar/features/reports/domain/monthly_report_options.dart';
import 'package:phakphum_calendar/features/reports/infrastructure/monthly_schedule_pdf_service.dart';

void main() {
  final service = MonthlySchedulePdfService();
  final options = MonthlyReportOptions(
    month: DateTime(2026, 1),
    generatedAt: DateTime(2026, 1, 31, 12),
  );

  test(
    'generates a valid landscape A4 PDF containing Thai report data',
    () async {
      final result = await service.generate(_thaiSchedule(), options);

      expect(result, isA<Success<Uint8List>>());
      final bytes = (result as Success<Uint8List>).value;
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('empty Schedule PDF generation succeeds', () async {
    final result = await service.generate(
      Schedule(id: 'empty', name: 'ไม่มีข้อมูล'),
      options,
    );

    expect(result, isA<Success<Uint8List>>());
    expect((result as Success<Uint8List>).value, isNotEmpty);
  });

  test(
    'large and long-name fixture generates a multi-page-safe PDF',
    () async {
      final result = await service.generate(_largeSchedule(), options);

      expect(result, isA<Success<Uint8List>>());
      expect((result as Success<Uint8List>).value.length, greaterThan(5000));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Schedule _thaiSchedule() {
  const department = Department(id: 'er', code: 'ER', name: 'ฉุกเฉิน');
  const employee = Employee(
    id: 'thai-1',
    employeeCode: '001',
    firstName: 'ภาคภูมิ',
    lastName: 'สุขใจ',
    nickname: 'ภูมิ',
    department: department,
    position: 'พยาบาลวิชาชีพ',
  );
  const shift = ShiftType(
    id: 'day',
    code: 'D',
    name: 'เวรเช้า',
    color: 0xFF1565C0,
    startTime: Duration(hours: 8),
    endTime: Duration(hours: 16),
    workingHours: 8,
  );
  return Schedule(
    id: 'thai',
    name: 'ตารางเวรโรงพยาบาล',
    months: [
      ScheduleMonth.empty(DateTime(2026, 1)).replaceDay(
        ScheduleDay(
          date: DateTime(2026, 1, 1),
          holidayName: 'วันขึ้นปีใหม่',
          assignments: const [
            ShiftAssignment(
              employee: employee,
              shift: shift,
              location: 'หอผู้ป่วยฉุกเฉิน',
              remark: 'หัวหน้าเวร',
            ),
          ],
        ),
      ),
    ],
  );
}

Schedule _largeSchedule() {
  const department = Department(id: 'ward', code: 'WARD', name: 'หอผู้ป่วย');
  const shift = ShiftType(
    id: 'day',
    code: 'D',
    name: 'เวรเช้า',
    color: 0xFF1565C0,
    startTime: Duration(hours: 8),
    endTime: Duration(hours: 16),
    workingHours: 8,
  );
  final assignments = [
    for (var index = 0; index < 80; index++)
      ShiftAssignment(
        employee: Employee(
          id: 'employee-$index',
          employeeCode: '$index',
          firstName: 'พนักงานชื่อยาวสำหรับทดสอบการตัดบรรทัดหมายเลข',
          lastName: '$index',
          nickname: '',
          department: department,
          position: 'พยาบาล',
        ),
        shift: shift,
      ),
  ];
  return Schedule(
    id: 'large',
    name: 'Large schedule',
    months: [
      ScheduleMonth.empty(DateTime(2026, 1)).replaceDay(
        ScheduleDay(date: DateTime(2026, 1, 1), assignments: assignments),
      ),
    ],
  );
}
