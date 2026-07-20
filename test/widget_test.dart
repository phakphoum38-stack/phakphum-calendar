import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/app.dart';
import 'package:phakphum_calendar/controller/app_controller.dart';
import 'package:phakphum_calendar/models/shift_alert.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('accepting an off conflict keeps the duty and removes OFF', () async {
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
    expect(controller.alertDecisions[conflict.id], ShiftAlertDecision.accepted);
    controller.dispose();
  });

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
    expect(find.text('รีเฟรช/อ่านใหม่ตอนนี้'), findsOneWidget);

    await tester.tap(find.text('แจ้งเตือน'));
    await tester.pumpAndSettle();
    expect(find.text('ศูนย์แจ้งเตือนเวร'), findsOneWidget);
    expect(find.text('ยอมรับ'), findsWidgets);
    expect(find.text('รับเวร'), findsWidgets);
    expect(find.text('ยกเลิก'), findsWidgets);

    await tester.tap(find.text('Adsite ตารางเวร'));
    await tester.pumpAndSettle();
    expect(
      find.text('ยังไม่มีข้อมูล — เว้นหน้านี้ไว้สำหรับอัปเดตภายหลัง'),
      findsOneWidget,
    );
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
}
