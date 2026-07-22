import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/rule_engine/application/rule_engine.dart';
import 'package:phakphum_calendar/features/rule_engine/domain/default_schedule_rules.dart';
import 'package:phakphum_calendar/features/rule_engine/domain/schedule_rule.dart';

void main() {
  test('detects overlapping shifts as blocking', () {
    final engine = RuleEngine(const [OverlappingShiftRule()]);
    final result = engine.evaluate([
      ScheduledShift(
        id: 'a',
        staffId: 'staff-1',
        start: DateTime(2026, 7, 1, 8),
        end: DateTime(2026, 7, 1, 16),
        kind: 'morning',
      ),
      ScheduledShift(
        id: 'b',
        staffId: 'staff-1',
        start: DateTime(2026, 7, 1, 15),
        end: DateTime(2026, 7, 1, 23),
        kind: 'afternoon',
      ),
    ]);

    expect(result.hasBlockingViolation, isTrue);
    expect(result.violations.single.ruleId, 'overlapping-shifts');
  });

  test('detects insufficient rest', () {
    final engine = RuleEngine(const [MinimumRestRule()]);
    final result = engine.evaluate([
      ScheduledShift(
        id: 'night',
        staffId: 'staff-1',
        start: DateTime(2026, 7, 1, 0),
        end: DateTime(2026, 7, 1, 8),
        kind: 'night',
      ),
      ScheduledShift(
        id: 'afternoon',
        staffId: 'staff-1',
        start: DateTime(2026, 7, 1, 12),
        end: DateTime(2026, 7, 1, 20),
        kind: 'afternoon',
      ),
    ]);

    expect(result.warningCount, 1);
  });
}
