import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_sync/presentation/screens/calendar_sync_screen.dart';

void main() {
  testWidgets('shows calendar sync screen information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarSyncScreen(
          accountEmail: 'phakphum@example.com',
          calendarName: 'เวรงาน ภาคภูมิ',
          selectedMonth: DateTime(2026, 7),
          shiftCount: 26,
          onPreview: () {},
          onSync: () {},
        ),
      ),
    );
    expect(find.text('ซิงก์ปฏิทิน'), findsNWidgets(2));
    expect(find.text('phakphum@example.com'), findsOneWidget);
    expect(find.text('เวรงาน ภาคภูมิ'), findsOneWidget);
    expect(find.text('กรกฎาคม 2569'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);

    final previewButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('calendarSyncPreviewButton')),
    );

    final syncButton = tester.widget<FilledButton>(
      find.byKey(const Key('calendarSyncButton')),
    );

    expect(previewButton.onPressed, isNotNull);
    expect(syncButton.onPressed, isNotNull);
  });

  testWidgets('disables actions when required data is missing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CalendarSyncScreen()));

    final previewButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('calendarSyncPreviewButton')),
    );

    final syncButton = tester.widget<FilledButton>(
      find.byKey(const Key('calendarSyncButton')),
    );

    expect(previewButton.onPressed, isNull);
    expect(syncButton.onPressed, isNull);
  });

  testWidgets('shows progress while busy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CalendarSyncScreen(isBusy: true)),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('กำลังประมวลผล...'), findsOneWidget);
    expect(find.byKey(const Key('calendarSyncButton')), findsNothing);
  });
}
