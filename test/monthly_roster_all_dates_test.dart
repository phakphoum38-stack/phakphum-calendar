import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/application/monthly_roster_section_parser.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/normalized_cell.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/shift_parser_input.dart';

void main() {
  const parser = MonthlyRosterSectionParser();
  const thaiMonths = <String>[
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  test(
    'maps every valid day of every month for every year from 1900 to 2200',
    () {
      for (var year = 1900; year <= 2200; year++) {
        final buddhistYear = year + 543;

        for (var month = 1; month <= 12; month++) {
          final lastDay = DateTime(year, month + 1, 0).day;
          final days = <int>[
            for (var day = 1; day <= lastDay; day++) day,
          ];
          final monthName = thaiMonths[month - 1];
          final title = '1 $monthName $buddhistYear - '
              '$lastDay $monthName $buddhistYear';

          final input = ShiftParserInput(
            spreadsheetId: 'spreadsheet',
            spreadsheetTitle: 'Roster',
            sheetId: 1,
            sheetTitle: title,
            timeZone: 'Asia/Bangkok',
            cells: [
              ..._row(0, ['เวร $title']),
              ..._row(1, ['วันที่', ...days]),
              ..._row(2, ['ER', ...days.map((day) => 'เวร $day')]),
            ],
          );

          final report = parser.parse(input);
          final actualDates = report.assignments
              .map((assignment) => assignment.date)
              .toList(growable: false);
          final expectedDates = <DateTime>[
            for (var day = 1; day <= lastDay; day++)
              DateTime(year, month, day),
          ];

          expect(
            report.warnings,
            isEmpty,
            reason: 'ไม่ควรมีคำเตือนสำหรับ $monthName $buddhistYear',
          );
          expect(
            actualDates,
            expectedDates,
            reason: 'วันที่ต้องตรงทุกวันใน $monthName $buddhistYear',
          );
        }
      }
    },
  );

  test(
    'rejects impossible days for every month from 1900 to 2200',
    () {
      for (var year = 1900; year <= 2200; year++) {
        final buddhistYear = year + 543;

        for (var month = 1; month <= 12; month++) {
          final lastDay = DateTime(year, month + 1, 0).day;
          if (lastDay == 31) continue;

          final invalidDay = lastDay + 1;
          final monthName = thaiMonths[month - 1];
          final title = '1 $monthName $buddhistYear - '
              '$lastDay $monthName $buddhistYear';

          final input = ShiftParserInput(
            spreadsheetId: 'spreadsheet',
            spreadsheetTitle: 'Roster',
            sheetId: 1,
            sheetTitle: title,
            timeZone: 'Asia/Bangkok',
            cells: [
              ..._row(0, ['เวร $title']),
              ..._row(1, ['วันที่', lastDay, invalidDay]),
              ..._row(2, ['ER', 'วันสุดท้าย', 'วันที่ไม่มีจริง']),
            ],
          );

          final report = parser.parse(input);

          expect(
            report.assignments.map((item) => item.date),
            [DateTime(year, month, lastDay)],
            reason: 'ต้องเก็บเฉพาะวันจริงของ $monthName $buddhistYear',
          );
          expect(
            report.warnings,
            isNotEmpty,
            reason: 'ต้องเตือนวันที่ $invalidDay $monthName $buddhistYear',
          );
        }
      }
    },
  );
}

List<NormalizedCell> _row(int rowIndex, List<Object?> values) {
  return [
    for (var columnIndex = 0; columnIndex < values.length; columnIndex++)
      if (values[columnIndex] != null)
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: '',
          rowIndex: rowIndex,
          columnIndex: columnIndex,
          text: values[columnIndex] is String
              ? values[columnIndex] as String
              : null,
          rawValue: values[columnIndex],
        ),
  ];
}
