import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/application/monthly_roster_section_parser.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/normalized_cell.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/shift_parser_input.dart';

void main() {
  test('applies Gregorian leap-year rules for every tested year', () {
    for (var gregorianYear = 1900; gregorianYear <= 2200; gregorianYear++) {
      final buddhistYear = gregorianYear + 543;
      final isLeapYear = _isLeapYear(gregorianYear);
      final input = _inputForYear(buddhistYear);

      final report = const MonthlyRosterSectionParser().parse(input);
      final dates = report.assignments.map((item) => item.date).toList();

      if (isLeapYear) {
        expect(
          dates,
          [DateTime(gregorianYear, 2, 29), DateTime(gregorianYear, 3, 1)],
          reason: 'ปี ค.ศ. $gregorianYear ต้องมีวันที่ 29 กุมภาพันธ์',
        );
        expect(
          report.warnings,
          isEmpty,
          reason: 'ปี ค.ศ. $gregorianYear ไม่ควรมีคำเตือนสำหรับ 29 กุมภาพันธ์',
        );
      } else {
        expect(
          dates,
          [DateTime(gregorianYear, 3, 1)],
          reason: 'ปี ค.ศ. $gregorianYear ต้องข้ามวันที่ 29 กุมภาพันธ์',
        );
        expect(
          report.warnings.any((warning) => warning.contains('วันที่ 29')),
          isTrue,
          reason: 'ปี ค.ศ. $gregorianYear ต้องแจ้งเตือนวันที่ 29 กุมภาพันธ์',
        );
      }
    }
  });

  test('handles century exceptions correctly', () {
    expect(_isLeapYear(1900), isFalse);
    expect(_isLeapYear(2000), isTrue);
    expect(_isLeapYear(2100), isFalse);
    expect(_isLeapYear(2200), isFalse);
    expect(_isLeapYear(2400), isTrue);
  });
}

bool _isLeapYear(int year) =>
    year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);

ShiftParserInput _inputForYear(int buddhistYear) {
  return ShiftParserInput(
    spreadsheetId: 'spreadsheet',
    spreadsheetTitle: 'Roster',
    sheetId: 1,
    sheetTitle: '28 ก.พ. $buddhistYear - 1 มี.ค. $buddhistYear',
    timeZone: 'Asia/Bangkok',
    cells: [
      ..._row(0, [
        'เวร 28 ก.พ. $buddhistYear - 1 มี.ค. $buddhistYear',
      ]),
      ..._row(1, ['วันที่', 28, 29, 1]),
      ..._row(2, ['ER', null, '29 ก.พ.', '1 มี.ค.']),
    ],
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
