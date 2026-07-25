import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/rule_engine/application/rule_engine.dart';
import 'package:phakphum_calendar/features/rule_engine/domain/default_schedule_rules.dart';
import 'package:phakphum_calendar/features/rule_engine/domain/schedule_rule.dart';
import 'package:phakphum_calendar/features/simulation/application/simulation_engine.dart';

void main() {
  group('SimulationEngine', () {
    late SimulationEngine simulationEngine;

    setUp(() {
      simulationEngine = SimulationEngine(
        ruleEngine: RuleEngine(const [
          InvalidShiftTimeRule(),
          OverlappingShiftRule(),
          MinimumRestRule(),
          MaximumWeeklyHoursRule(),
        ]),
      );
    });

    test('allows valid shifts to be prepared for sync', () {
      final shifts = [
        ScheduledShift(
          id: 'shift-1',
          staffId: 'staff-1',
          start: DateTime(2026, 7, 27, 8),
          end: DateTime(2026, 7, 27, 16),
          kind: 'morning',
        ),
      ];

      final result = simulationEngine.simulate(shifts);

      expect(result.totalShiftCount, 1);
      expect(result.readyCount, 1);
      expect(result.blockedCount, 0);
      expect(result.canSync, isTrue);
    });

    test('blocks shifts involved in overlapping schedules', () {
      final shifts = [
        ScheduledShift(
          id: 'shift-1',
          staffId: 'staff-1',
          start: DateTime(2026, 7, 27, 8),
          end: DateTime(2026, 7, 27, 16),
          kind: 'morning',
        ),
        ScheduledShift(
          id: 'shift-2',
          staffId: 'staff-1',
          start: DateTime(2026, 7, 27, 15),
          end: DateTime(2026, 7, 27, 23),
          kind: 'afternoon',
        ),
      ];

      final result = simulationEngine.simulate(shifts);

      expect(result.totalShiftCount, 2);
      expect(result.readyCount, 0);
      expect(result.blockedCount, 1);
      expect(result.canSync, isFalse);
      expect(result.blockingViolations.single.ruleId, 'overlapping-shifts');
    });

    test('keeps warnings without blocking synchronization', () {
      final shifts = [
        ScheduledShift(
          id: 'shift-1',
          staffId: 'staff-1',
          start: DateTime(2026, 7, 27, 8),
          end: DateTime(2026, 7, 27, 16),
          kind: 'morning',
        ),
        ScheduledShift(
          id: 'shift-2',
          staffId: 'staff-1',
          start: DateTime(2026, 7, 27, 22),
          end: DateTime(2026, 7, 28, 6),
          kind: 'night',
        ),
      ];

      final result = simulationEngine.simulate(shifts);

      expect(result.readyCount, 2);
      expect(result.warningCount, 1);
      expect(result.blockedCount, 0);
      expect(result.canSync, isTrue);
    });

    test('blocks a shift with an invalid time range', () {
      final shifts = [
        ScheduledShift(
          id: 'invalid-shift',
          staffId: 'staff-1',
          start: DateTime(2026, 7, 27, 16),
          end: DateTime(2026, 7, 27, 8),
          kind: 'unknown',
        ),
      ];

      final result = simulationEngine.simulate(shifts);

      expect(result.readyCount, 0);
      expect(result.blockedCount, 1);
      expect(result.canSync, isFalse);
      expect(result.blockingViolations.single.ruleId, 'unknown_shift_time');
    });
  });
}
