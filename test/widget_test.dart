import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/app.dart';
import 'package:phakphum_calendar/controller/app_controller.dart';

void main() {
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
