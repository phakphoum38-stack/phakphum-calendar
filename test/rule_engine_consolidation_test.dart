import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/validation/rule_evaluator.dart';
import 'package:phakphum_calendar/features/excel_import/domain/shift_record.dart';
import 'package:phakphum_calendar/features/rule_engine/application/rule_engine.dart'
    as legacy;
import 'package:phakphum_calendar/features/rule_engine/domain/schedule_rule.dart'
    as legacy;
import 'package:phakphum_calendar/features/rules/application/rule_engine.dart'
    as canonical;
import 'package:phakphum_calendar/features/rules/domain/schedule_rules.dart';
import 'package:phakphum_calendar/features/schedule/data/imported_schedule_adapter.dart';

void main() {
  group('canonical rule evaluation pipeline', () {
    test('validates imported schedules through the canonical evaluator', () {
      const adapter = ImportedScheduleAdapter();
      final schedule = adapter.createSchedule([
        ShiftRecord(
          date: DateTime(2026, 7, 24),
          shift: 'Day',
          employee: 'Anan',
          rowNumber: 2,
        ),
      ]);
      final engine = canonical.RuleEngine(
        rules: const [InvalidShiftDurationRule()],
      );

      final result = engine.validateSchedule(schedule);

      expect(result.errors.single.ruleId, 'invalid-shift-duration');
    });

    test('validates calendar schedules through the canonical evaluator', () {
      const adapter = ImportedScheduleAdapter();
      final schedule = adapter.createSchedule([
        ShiftRecord(
          date: DateTime(2026, 7, 4),
          shift: 'Day',
          employee: 'Anan',
          rowNumber: 2,
        ),
      ]);
      final engine = canonical.RuleEngine(rules: const [WeekendRule()]);

      final result = engine.validateSchedule(schedule);

      expect(result.warnings.single.ruleId, 'weekend-rule');
    });

    test('legacy wrapper executes a duplicated rule only once', () {
      final rule = _CountingLegacyRule();
      final engine = legacy.RuleEngine([rule, rule]);

      final result = engine.evaluate(const []);

      expect(rule.executionCount, 1);
      expect(result.violations, isEmpty);
    });

    test('RuleEvaluator retains ordering, deduplication, and immutability', () {
      const evaluator = RuleEvaluator();

      final results = evaluator.evaluate<String, void, String>(
        rules: const ['first', 'second', 'first'],
        context: null,
        ruleId: (rule) => rule,
        evaluateRule: (rule, _) => ['$rule-violation'],
      );

      expect(results.map((result) => result.ruleId), ['first', 'second']);
      expect(results.expand((result) => result.violations), [
        'first-violation',
        'second-violation',
      ]);
      expect(() => results.add(results.first), throwsUnsupportedError);
      expect(
        () => results.first.violations.add('another'),
        throwsUnsupportedError,
      );
    });
  });
}

final class _CountingLegacyRule implements legacy.ScheduleRule {
  int executionCount = 0;

  @override
  String get id => 'counting-rule';

  @override
  List<legacy.RuleViolation> evaluate(List<legacy.ScheduledShift> shifts) {
    executionCount += 1;
    return const [];
  }
}
