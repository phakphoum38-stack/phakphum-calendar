import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/app.dart';
import 'package:phakphum_calendar/core/di/app_dependencies.dart';
import 'package:phakphum_calendar/features/reports/domain/report_labels.dart';
import 'package:phakphum_calendar/features/schedule/presentation/pages/monthly_schedule_page.dart';
import 'package:phakphum_calendar/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('application switches between Thai and English at runtime', (
    tester,
  ) async {
    final controller = AppDependencies.production().createDemoAppController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ShiftToolsApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('แดชบอร์ด'), findsOneWidget);
    expect(find.text('รายงาน'), findsOneWidget);

    await tester.tap(find.byKey(const Key('locale-switch')));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('report controls render in Thai and English', (tester) async {
    final controller = AppDependencies.production().createDemoAppController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ShiftToolsApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('รายงาน'));
    await tester.pumpAndSettle();
    expect(find.text('สร้างตัวอย่าง'), findsOneWidget);
    expect(find.text('ทุกแผนก'), findsOneWidget);

    await tester.tap(find.byKey(const Key('locale-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Generate preview'), findsOneWidget);
    expect(find.text('All departments'), findsOneWidget);
  });

  testWidgets('calendar empty state follows the selected locale', (
    tester,
  ) async {
    await tester.pumpWidget(_localizedApp(const Locale('th')));
    expect(find.text('ไม่มีเวรในเดือนนี้'), findsOneWidget);

    await tester.pumpWidget(_localizedApp(const Locale('en')));
    await tester.pump();
    expect(find.text('No shifts scheduled for this month.'), findsOneWidget);
  });

  test('report migration boundary supplies Thai and English copy', () {
    expect(
      ReportLabels.forLanguageCode('th').defaultTitle,
      'รายงานตารางเวรประจำเดือน',
    );
    expect(
      ReportLabels.forLanguageCode('en').defaultTitle,
      'Monthly Staff Schedule Report',
    );
  });
}

Widget _localizedApp(Locale locale) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Scaffold(body: MonthlySchedulePage()),
  );
}
