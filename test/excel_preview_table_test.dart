import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/excel_import/domain/excel_cell.dart';
import 'package:phakphum_calendar/features/excel_import/domain/excel_row.dart';
import 'package:phakphum_calendar/features/excel_import/domain/worksheet_info.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/widgets/excel_preview_table.dart';

void main() {
  testWidgets('renders metadata, headers, row numbers, and sparse values', (
    tester,
  ) async {
    const worksheet = WorksheetInfo(
      name: 'Roster',
      rowCount: 75,
      columnCount: 28,
    );
    final rows = [
      ExcelRow(
        index: 0,
        cells: const [
          ExcelCell(rowIndex: 0, columnIndex: 0, value: 'Name'),
          ExcelCell(rowIndex: 0, columnIndex: 2, value: 'Shift'),
        ],
      ),
      for (var index = 1; index < 50; index++)
        ExcelRow(
          index: index,
          cells: [
            ExcelCell(rowIndex: index, columnIndex: 0, value: 'Person $index'),
          ],
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: ExcelPreviewTable(worksheet: worksheet, rows: rows),
          ),
        ),
      ),
    );

    expect(find.text('Roster'), findsOneWidget);
    expect(find.textContaining('75 แถว'), findsOneWidget);
    expect(find.textContaining('28 คอลัมน์'), findsOneWidget);
    expect(find.textContaining('แสดง 50 แถวแรก'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('AA'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Shift'), findsOneWidget);

    final scrollables = tester.widgetList<Scrollable>(find.byType(Scrollable));
    expect(
      scrollables.any(
        (scrollable) => scrollable.axisDirection == AxisDirection.right,
      ),
      isTrue,
    );
    expect(
      scrollables.any(
        (scrollable) => scrollable.axisDirection == AxisDirection.down,
      ),
      isTrue,
    );

    final verticalScrollable = tester.state<ScrollableState>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    verticalScrollable.position.jumpTo(300);
    await tester.pump();

    expect(find.text('A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
