import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/controllers/column_mapping_controller.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/pages/column_mapping_page.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/widgets/duplicate_warning_card.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/widgets/validation_banner.dart';

void main() {
  testWidgets('shows required validation and duplicate warnings', (
    tester,
  ) async {
    final controller = ColumnMappingController()
      ..loadAvailableColumns(['A', 'B', 'C']);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ColumnMappingPage(controller: controller, onNext: (_) {}),
      ),
    );

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(6));
    expect(find.text('Required *'), findsNWidgets(3));
    expect(find.text('Optional'), findsNWidgets(3));

    await tester.ensureVisible(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.byType(ValidationBanner), findsOneWidget);
    expect(find.textContaining('Date, Shift, Employee'), findsOneWidget);

    controller.updateMapping(DestinationField.date, 'A');
    controller.updateMapping(DestinationField.shift, 'A');
    await tester.pump();

    expect(find.byType(DuplicateWarningCard), findsOneWidget);
    expect(find.textContaining('Duplicate columns: A'), findsOneWidget);
    expect(find.text('คอลัมน์นี้ถูกเลือกซ้ำ'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
