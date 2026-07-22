import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/application/hospital_roster_parser.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/normalized_cell.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/shift_parser_input.dart';

void main() {
  test('parses the observed hospital roster layout', () {
    const input = ShiftParserInput(
      spreadsheetId: 'spreadsheet',
      spreadsheetTitle: 'Roster',
      sheetId: 1,
      sheetTitle: '16 กค69-15 สค.69',
      timeZone: 'Asia/Bangkok',
      cells: [
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: 'A1',
          rowIndex: 0,
          columnIndex: 0,
          text: 'เวร',
        ),
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: 'A2',
          rowIndex: 1,
          columnIndex: 0,
          text: 'วันที่',
        ),
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: 'B2',
          rowIndex: 1,
          columnIndex: 1,
          rawValue: 16,
        ),
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: 'C3',
          rowIndex: 2,
          columnIndex: 2,
          text: 'ประจำเดือน 16 กรกฎาคม พ.ศ. 2569 - 15 สิงหาคม พ.ศ. 2569',
        ),
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: 'A10',
          rowIndex: 9,
          columnIndex: 0,
          text: 'P2 บ่าย',
        ),
        NormalizedCell(
          sheetId: 1,
          sheetTitle: 'Sheet',
          a1: 'B10',
          rowIndex: 9,
          columnIndex: 1,
          text: 'ภาคภูมิ',
        ),
      ],
    );

    final report = const HospitalRosterParser().parse(input);
    expect(report.assignments, hasLength(1));
    expect(report.assignments.single.date, DateTime(2026, 7, 16));
    expect(report.assignments.single.category, 'Portable');
    expect(report.assignments.single.period, 'บ่าย');
    expect(report.assignments.single.slot, 'P2');
    expect(report.assignments.single.workerName, 'ภาคภูมิ');
  });
}
