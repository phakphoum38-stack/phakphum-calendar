import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/di/app_dependencies.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/features/excel_import/application/import_engine.dart';
import 'package:phakphum_calendar/features/excel_import/data/google_sheets_import_data_source.dart';
import 'package:phakphum_calendar/features/excel_import/domain/column_mapping.dart';
import 'package:phakphum_calendar/features/excel_import/domain/excel_cell.dart';
import 'package:phakphum_calendar/features/excel_import/domain/excel_row.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/sheet_cell.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/sheets_gateway.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/spreadsheet_snapshot.dart';
import 'package:phakphum_calendar/features/schedule/data/shared_preferences_schedule_repository.dart';

import 'support/in_memory_schedule_store.dart';

void main() {
  test('parses spreadsheet metadata for the import boundary', () async {
    final source = GoogleSheetsImportDataSource(
      _FakeSheetsGateway(_spreadsheet()),
    );

    final metadata = await source.readMetadata('requested-id');

    expect(metadata.spreadsheetId, 'spreadsheet-123');
    expect(metadata.title, 'July roster');
    expect(metadata.locale, 'th_TH');
    expect(metadata.timeZone, 'Asia/Bangkok');
    expect(metadata.worksheetCount, 2);
  });

  test('lists available worksheets from spreadsheet metadata', () async {
    final source = GoogleSheetsImportDataSource(
      _FakeSheetsGateway(_spreadsheet()),
    );
    await source.readMetadata('spreadsheet-123');

    final worksheets = source.listWorksheets();

    expect(worksheets.map((sheet) => sheet.name), ['Roster', 'Summary']);
    expect(worksheets.first.rowCount, 100);
    expect(worksheets.first.columnCount, 6);
  });

  test(
    'converts selected worksheet rows into the existing import flow',
    () async {
      final source = GoogleSheetsImportDataSource(
        _FakeSheetsGateway(_spreadsheet()),
      );
      final metadata = await source.readMetadata('spreadsheet-123');
      final worksheet = metadata.worksheets.first;

      final rows = source.selectWorksheet(worksheet);
      final result = const ImportEngine().convertRows(
        rows: rows,
        mapping: const ColumnMapping(
          dateColumn: 'A',
          shiftColumn: 'B',
          employeeColumn: 'C',
        ),
      );

      expect(source.selectedWorksheet, same(worksheet));
      expect(rows, hasLength(3));
      expect(rows[1].cells[2].value, 'Anan');
      expect(rows[2].cells[2].value, 'Mali');
      expect(result.records, hasLength(2));
      expect(result.records.map((record) => record.employee), ['Anan', 'Mali']);

      final dependencies = AppDependencies(
        scheduleRepository: SharedPreferencesScheduleRepository(
          store: InMemoryScheduleKeyValueStore(),
        ),
      );
      final schedule = dependencies.createImportedSchedule(result.records);
      final persisted = await dependencies.saveImportedSchedule(schedule);
      final controller = dependencies.createImportedScheduleController(
        schedule,
      );
      addTearDown(controller.dispose);

      expect(schedule, isA<Schedule>());
      expect(persisted.isSuccess, isTrue);
      expect(controller.canonicalSchedule, same(schedule));
      expect(controller.currentMonth, DateTime(2026, 7));
      expect(
        controller.schedule
            .day(DateTime(2026, 7, 24))!
            .assignments
            .single
            .employee
            .firstName,
        'Anan',
      );

      final excelEquivalent = const ImportEngine().convertRows(
        rows: [
          ExcelRow(
            index: 0,
            cells: const [
              ExcelCell(rowIndex: 0, columnIndex: 0, value: 'Date'),
              ExcelCell(rowIndex: 0, columnIndex: 1, value: 'Shift'),
              ExcelCell(rowIndex: 0, columnIndex: 2, value: 'Employee'),
            ],
          ),
          ExcelRow(
            index: 1,
            cells: const [
              ExcelCell(rowIndex: 1, columnIndex: 0, value: '24/07/2026'),
              ExcelCell(rowIndex: 1, columnIndex: 1, value: 'Morning'),
              ExcelCell(rowIndex: 1, columnIndex: 2, value: 'Anan'),
            ],
          ),
          ExcelRow(
            index: 2,
            cells: const [
              ExcelCell(rowIndex: 2, columnIndex: 0, value: '25/07/2026'),
              ExcelCell(rowIndex: 2, columnIndex: 1, value: 'Night'),
              ExcelCell(rowIndex: 2, columnIndex: 2, value: 'Mali'),
            ],
          ),
        ],
        mapping: const ColumnMapping(
          dateColumn: 'A',
          shiftColumn: 'B',
          employeeColumn: 'C',
        ),
      );
      final excelSchedule = dependencies.createImportedSchedule(
        excelEquivalent.records,
      );
      expect(_scheduleValues(schedule), _scheduleValues(excelSchedule));
    },
  );
}

List<String> _scheduleValues(Schedule schedule) {
  return [
    for (final month in schedule.months)
      for (final day in month.days)
        for (final assignment in day.assignments)
          '${day.date.toIso8601String()}|${assignment.shift.name}|'
              '${assignment.employee.firstName}',
  ];
}

class _FakeSheetsGateway implements SheetsGateway {
  const _FakeSheetsGateway(this.snapshot);

  final SpreadsheetSnapshot snapshot;

  @override
  Future<SpreadsheetSnapshot> readSpreadsheet({
    required String spreadsheetId,
    bool includeGridData = true,
  }) async {
    return snapshot;
  }
}

SpreadsheetSnapshot _spreadsheet() {
  return const SpreadsheetSnapshot(
    spreadsheetId: 'spreadsheet-123',
    title: 'July roster',
    locale: 'th_TH',
    timeZone: 'Asia/Bangkok',
    sheets: [
      SpreadsheetSheetSnapshot(
        sheetId: 10,
        title: 'Roster',
        rowCount: 100,
        columnCount: 6,
        mergedRanges: [],
        cells: [
          SheetCell(
            sheetId: 10,
            rowIndex: 0,
            columnIndex: 0,
            a1: 'A1',
            formattedValue: 'Date',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 0,
            columnIndex: 1,
            a1: 'B1',
            formattedValue: 'Shift',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 0,
            columnIndex: 2,
            a1: 'C1',
            formattedValue: 'Employee',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 1,
            columnIndex: 0,
            a1: 'A2',
            formattedValue: '24/07/2026',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 1,
            columnIndex: 1,
            a1: 'B2',
            formattedValue: 'Morning',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 1,
            columnIndex: 2,
            a1: 'C2',
            formattedValue: 'Anan',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 2,
            columnIndex: 0,
            a1: 'A3',
            formattedValue: '25/07/2026',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 2,
            columnIndex: 1,
            a1: 'B3',
            formattedValue: 'Night',
          ),
          SheetCell(
            sheetId: 10,
            rowIndex: 2,
            columnIndex: 2,
            a1: 'C3',
            formattedValue: 'Mali',
          ),
        ],
      ),
      SpreadsheetSheetSnapshot(
        sheetId: 20,
        title: 'Summary',
        rowCount: 20,
        columnCount: 4,
        mergedRanges: [],
        cells: [],
      ),
    ],
  );
}
