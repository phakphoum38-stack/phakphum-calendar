import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_category.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_result.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_severity.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_violation.dart';
import 'package:phakphum_calendar/features/rules/domain/schedule_rules.dart';
import 'package:phakphum_calendar/features/rules/presentation/pages/rule_validation_page.dart';

void main() {
  testWidgets('displays errors, warnings, and passed rules', (tester) async {
    const rules = [
      WeekendRule(),
      MaximumShiftsPerMonthRule(maximum: 20),
      HolidayRule(),
    ];
    final result = RuleResult(
      passedRules: const ['Holiday rule'],
      violations: [
        const RuleViolation(
          ruleId: 'maximum-shifts-per-month',
          ruleName: 'Maximum shifts per month',
          employeeId: 'e1',
          message: 'Too many shifts',
          severity: RuleSeverity.error,
          category: RuleCategory.workload,
        ),
        const RuleViolation(
          ruleId: 'weekend-rule',
          ruleName: 'Weekend rule',
          message: 'Weekend assignment',
          severity: RuleSeverity.warning,
          category: RuleCategory.weekend,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RuleValidationPage(result: result, rules: rules),
      ),
    );

    expect(find.text('Rule Validation'), findsOneWidget);
    expect(find.text('1 Errors'), findsOneWidget);
    expect(find.text('1 Warnings'), findsOneWidget);
    expect(find.text('1 Passed rules'), findsOneWidget);
    expect(find.text('Too many shifts'), findsOneWidget);
    expect(find.text('Weekend assignment'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Holiday rule'), findsOneWidget);
    expect(find.text('Passed'), findsOneWidget);
  });
}
