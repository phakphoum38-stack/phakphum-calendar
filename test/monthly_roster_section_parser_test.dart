import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/application/monthly_roster_section_parser.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/normalized_cell.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/shift_parser_input.dart';

void main() {
  test('discovers monthly blocks and keeps section and row labels dynamic', () {
    final cells = <NormalizedCell>[
      ..._row(0, ['เวรใหญ่ ประจำเดือน กรกฎาคม พ.ศ. 2569']),
      ..._row(1, ['เวร', 'พ', 'พฤ', 'ศ', 'ส', 'อา', 'จ', 'อ']),
      ..._row(2, ['วันที่', 1, 2, 3, 4, 5, 6, 7]),
      ..._row(3, ['MRI', 'ก', 'ข', null, null, null, null, null]),
      ..._row(4, ['MRI', 'ง', null, null, null, null, null, null]),
      ..._row(6, ['GEN คลินิคพิเศษ ประจำเดือน กรกฎาคม พ.ศ. 2569']),
      ..._row(7, ['เวร', 'พ', 'พฤ', 'ศ', 'ส', 'อา', 'จ', 'อ']),
      ..._row(8, ['วันที่', 1, 2, 3, 4, 5, 6, 7]),
      ..._row(9, ['คลินิก A', 'ค', null, null, null, null, null, null]),
    ];
    final input = ShiftParserInput(
      spreadsheetId: 'spreadsheet',
      spreadsheetTitle: 'Roster',
      sheetId: 1666384927,
      sheetTitle: 'ตารางเวรรายเดือน',
      timeZone: 'Asia/Bangkok',
      cells: cells,
    );

    final report = const MonthlyRosterSectionParser().parse(input);

    expect(report.warnings, isEmpty);
    expect(report.sections, hasLength(2));
    expect(report.sections.first.title, contains('เวรใหญ่'));
    expect(report.sections.last.title, contains('คลินิคพิเศษ'));
    expect(report.assignments, hasLength(4));
    expect(report.assignments.first.rowLabel, 'MRI');
    expect(report.assignments.first.date, DateTime(2026, 7, 1));
    expect(
      report.sections.first.assignments.map((item) => item.rowIndex).toSet(),
      containsAll(<int>{3, 4}),
    );
    expect(report.assignments.last.rowLabel, 'คลินิก A');
    expect(report.assignments.last.sourceCell, 'B10');
  });

  test('does not require fixed names for exten or future sections', () {
    final input = ShiftParserInput(
      spreadsheetId: 'spreadsheet',
      spreadsheetTitle: 'Roster',
      sheetId: 1,
      sheetTitle: 'รายเดือน',
      timeZone: 'Asia/Bangkok',
      cells: [
        ..._row(0, ['Exten ใหม่ ประจำเดือน สิงหาคม พ.ศ. 2569']),
        ..._row(1, ['วันที่', 1, 2, 3, 4, 5, 6, 7]),
        ..._row(2, ['ห้องทดลองใหม่', 'ภาคภูมิ']),
      ],
    );

    final report = const MonthlyRosterSectionParser().parse(input);

    expect(report.sections.single.title, startsWith('Exten ใหม่'));
    expect(report.assignments.single.rowLabel, 'ห้องทดลองใหม่');
    expect(report.assignments.single.workerName, 'ภาคภูมิ');
    expect(report.assignments.single.date, DateTime(2026, 8, 1));
  });
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
