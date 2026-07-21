import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/app.dart';
import 'package:phakphum_calendar/controller/app_controller.dart';
import 'package:phakphum_calendar/models/shift_alert.dart';
import 'package:phakphum_calendar/services/drive_ownership_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'accepting an OFF conflict keeps duty and excludes generated OFF',
    () async {
      final controller = AppController.demo();
      final conflict = controller.alerts.singleWhere(
        (alert) => alert.type == ShiftAlertType.offConflict,
      );

      await controller.resolveAlert(conflict.id, ShiftAlertDecision.accepted);

      expect(
        controller.shifts.singleWhere((shift) => shift.code == 'OFF').excluded,
        isTrue,
      );
      expect(
        controller.shifts.singleWhere((shift) => shift.code == 'UP3').excluded,
        isFalse,
      );
      controller.dispose();
    },
  );

  testWidgets('desktop layout shows the full navigation and dashboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PhakphumCalendarApp(controller: AppController.demo()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Shift Calendar'), findsOneWidget);
    expect(find.text('แหล่งข้อมูลเวร'), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('เข้าสู่ระบบด้วย Google'), findsOneWidget);
    expect(find.text('รีเฟรช/อ่านใหม่ตอนนี้'), findsOneWidget);
    expect(find.text('ชื่อที่ต้องค้นหา'), findsOneWidget);
    expect(find.text('กรอกชื่อให้ตรงกับชื่อในตารางเวร'), findsOneWidget);
    expect(find.text('ค้นหาจากประวัติอัปเดต Sheets'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNWidgets(2));
    expect(find.text('${DateTime.now().year}'), findsNothing);

    await tester.tap(find.text('แจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('ศูนย์แจ้งเตือนเวร'), findsOneWidget);
    expect(find.text('รับทราบและคงไว้'), findsWidgets);
    expect(find.text('ไม่นำเข้าปฏิทิน'), findsWidgets);

    await tester.tap(find.text('หน้าแรก'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year + 1}').last);
    await tester.pumpAndSettle();
    expect(find.text('${DateTime.now().year + 1}'), findsOneWidget);

    await tester.tap(find.text('เครื่องมือ'));
    await tester.pumpAndSettle();
    expect(find.text('คลังเครื่องมือ'), findsOneWidget);
    expect(find.text('Gmail'), findsWidgets);
    expect(find.text('VS Code Web'), findsWidgets);
    expect(find.text('ติดตั้งในแถบ'), findsWidgets);

    await tester.tap(find.text('ตั้งค่า'));
    await tester.pumpAndSettle();
    expect(find.text('สร้างชีตเดือนล่วงหน้า'), findsOneWidget);
    expect(find.textContaining('Passkey'), findsNothing);
    expect(find.textContaining('passkey'), findsNothing);
  });

  testWidgets('phone layout remains usable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PhakphumCalendarApp(controller: AppController.demo()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Auto refresh'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recent Sheet history remains usable on a phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = AppController.demo()
      ..recentSheetHistoryLoaded = true
      ..recentOwnedSheets = [
        RecentOwnedSheet(
          id: 'recent-sheet-id',
          name: 'ตารางเวรล่าสุด',
          url: 'https://docs.google.com/spreadsheets/d/recent-sheet-id/edit',
          modifiedAt: DateTime(2026, 7, 21, 8, 30),
        ),
      ];
    addTearDown(controller.dispose);

    await tester.pumpWidget(PhakphumCalendarApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('ไฟล์ที่คุณอัปเดตล่าสุด'), findsOneWidget);
    expect(find.text('ตารางเวรล่าสุด'), findsOneWidget);
    expect(find.byTooltip('ใช้เป็นไฟล์หลัก'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved Sheets controls are visible in the audit tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PhakphumCalendarApp(controller: AppController.demo()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();

    expect(find.text('ชีตที่บันทึก'), findsOneWidget);
    expect(find.text('บันทึกชีตปัจจุบัน'), findsOneWidget);
    expect(find.textContaining('ล็อกอิน Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tools library remains usable in phone landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PhakphumCalendarApp(controller: AppController.demo()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Notion'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Windows explains that Google actions use the web app', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        PhakphumCalendarApp(controller: AppController.demo()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Google Login ใช้ผ่าน Web'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
