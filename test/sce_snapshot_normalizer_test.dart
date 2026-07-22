import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/grid_range.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/sheet_cell.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/spreadsheet_snapshot.dart';
import 'package:phakphum_calendar/features/shift_parser/application/snapshot_normalizer.dart';

void main() {
  test('normalizes cells while preserving merge metadata', () {
    const snapshot = SpreadsheetSnapshot(
      spreadsheetId: 'spreadsheet-id',
      title: 'Roster',
      locale: 'th_TH',
      timeZone: 'Asia/Bangkok',
      sheets: [
        SpreadsheetSheetSnapshot(
          sheetId: 1,
          title: 'August',
          rowCount: 10,
          columnCount: 10,
          mergedRanges: [
            SheetGridRange(
              sheetId: 1,
              startRowIndex: 0,
              endRowIndex: 1,
              startColumnIndex: 0,
              endColumnIndex: 2,
            ),
          ],
          cells: [
            SheetCell(
              sheetId: 1,
              rowIndex: 0,
              columnIndex: 0,
              a1: 'A1',
              formattedValue: '  Header  ',
              isMerged: true,
              mergedAnchorA1: 'A1',
            ),
          ],
        ),
      ],
    );

    final inputs = const SnapshotNormalizer().normalize(snapshot);

    expect(inputs, hasLength(1));
    expect(inputs.single.timeZone, 'Asia/Bangkok');
    expect(inputs.single.cells.single.text, 'Header');
    expect(inputs.single.cells.single.isMerged, isTrue);
    expect(inputs.single.cells.single.mergedAnchorA1, 'A1');
  });
}
