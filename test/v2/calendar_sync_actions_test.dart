import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_sync/presentation/screens/calendar_sync_screen.dart';

void main() {
  Widget buildScreen({
    CalendarSyncAction? onPreview,
    CalendarSyncAction? onSync,
  }) {
    return MaterialApp(
      home: CalendarSyncScreen(
        accountEmail: 'phakphum@example.com',
        calendarName: 'ตารางเวรภาคภูมิ',
        selectedMonth: DateTime(2026, 7),
        shiftCount: 12,
        onPreview: onPreview,
        onSync: onSync,
      ),
    );
  }

  testWidgets('calls preview callback and shows success message', (
    tester,
  ) async {
    var previewCalled = false;

    await tester.pumpWidget(
      buildScreen(
        onPreview: () async {
          previewCalled = true;
        },
        onSync: () {},
      ),
    );

    final previewButton = find.byKey(const Key('calendarSyncPreviewButton'));

    await tester.ensureVisible(previewButton);
    await tester.tap(previewButton);
    await tester.pumpAndSettle();

    expect(previewCalled, isTrue);
    expect(find.text('สร้างตัวอย่างรายการเรียบร้อยแล้ว'), findsOneWidget);
  });

  testWidgets('calls sync callback and shows success message', (tester) async {
    var syncCalled = false;

    await tester.pumpWidget(
      buildScreen(
        onPreview: () {},
        onSync: () async {
          syncCalled = true;
        },
      ),
    );

    final syncButton = find.byKey(const Key('calendarSyncButton'));

    await tester.ensureVisible(syncButton);
    await tester.tap(syncButton);
    await tester.pumpAndSettle();

    expect(syncCalled, isTrue);
    expect(find.text('ซิงก์ปฏิทินเรียบร้อยแล้ว'), findsOneWidget);
  });

  testWidgets('shows error message when sync callback fails', (tester) async {
    await tester.pumpWidget(
      buildScreen(
        onPreview: () {},
        onSync: () {
          throw Exception('เกิดข้อผิดพลาดจำลอง');
        },
      ),
    );

    final syncButton = find.byKey(const Key('calendarSyncButton'));

    await tester.ensureVisible(syncButton);
    await tester.tap(syncButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendarSyncErrorSnackBar')), findsOneWidget);

    expect(find.textContaining('ไม่สามารถซิงก์ปฏิทินได้'), findsOneWidget);
  });
}
