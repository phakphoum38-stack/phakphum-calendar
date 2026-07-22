import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_diff.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';
import 'package:phakphum_calendar/features/simulation/application/simulation_plan_builder.dart';
import 'package:phakphum_calendar/features/simulation/domain/simulation_item.dart';

void main() {
  test('builds summary and preview items from calendar diff', () {
    final start = DateTime(2026, 8, 4, 8);
    final end = DateTime(2026, 8, 4, 16);

    final event = CalendarEventCandidate(
      syncId: 'sync-1',
      title: 'ER เช้า',
      start: start,
      end: end,
      shouldExist: true,
    );

    final plan = const SimulationPlanBuilder().build(
      diff: CalendarDiff(
        toAdd: [event],
        toUpdate: const [],
        toDelete: const [],
        unchanged: const [],
      ),
      warningCount: 1,
      blockedCount: 0,
      generatedAt: DateTime(2026, 7, 22),
    );

    expect(plan.summary.addCount, 1);
    expect(plan.summary.warningCount, 1);
    expect(plan.items.single.action, SimulationAction.add);
    expect(plan.summary.canSynchronize, isTrue);
  });
}
