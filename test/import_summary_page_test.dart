import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/excel_import/domain/import_issue.dart';
import 'package:phakphum_calendar/features/excel_import/domain/import_summary.dart';
import 'package:phakphum_calendar/features/excel_import/domain/shift_record.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/pages/import_summary_page.dart';

void main() {
  testWidgets('displays statistics, warnings, errors, and success percentage', (
    tester,
  ) async {
    final summary = ImportSummary(
      totalRows: 4,
      importedRows: 2,
      skippedRows: 1,
      errorRows: 1,
      issues: const [
        ImportIssue(
          rowNumber: 3,
          column: 'A',
          message: 'Invalid date',
          severity: ImportIssueSeverity.error,
        ),
        ImportIssue(
          rowNumber: 4,
          column: 'Row',
          message: 'Duplicate shift record',
          severity: ImportIssueSeverity.warning,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ImportSummaryPage(
          summary: summary,
          records: const [
            ShiftRecord(
              date: null,
              shift: 'Morning',
              employee: 'Anan',
              rowNumber: 2,
            ),
            ShiftRecord(
              date: null,
              shift: 'Morning',
              employee: 'Anan',
              rowNumber: 4,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Imported rows'), findsOneWidget);
    expect(find.text('Skipped rows'), findsOneWidget);
    expect(find.text('Error rows'), findsOneWidget);
    expect(find.text('Errors'), findsOneWidget);
    expect(find.text('Warnings'), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget);
    expect(find.text('Invalid date'), findsOneWidget);
    expect(find.text('Duplicate shift record'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
