import '../../rule_engine/application/rule_engine.dart';
import '../../rule_engine/domain/schedule_rule.dart';
import '../domain/simulation_result.dart';

class SimulationEngine {
  const SimulationEngine({required this.ruleEngine});

  final RuleEngine ruleEngine;

  SimulationResult simulate(List<ScheduledShift> shifts) {
    final immutableShifts = List<ScheduledShift>.unmodifiable(shifts);
    final evaluation = ruleEngine.evaluate(immutableShifts);

    final blockingViolations = evaluation.violations
        .where((violation) => violation.severity == RuleSeverity.blocking)
        .toList(growable: false);

    final warningViolations = evaluation.violations
        .where((violation) => violation.severity == RuleSeverity.warning)
        .toList(growable: false);

    final blockedShiftIds = blockingViolations
        .expand((violation) => violation.shiftIds)
        .toSet();

    final readyShifts = immutableShifts
        .where((shift) => !blockedShiftIds.contains(shift.id))
        .toList(growable: false);

    return SimulationResult(
      totalShiftCount: immutableShifts.length,
      readyShifts: List.unmodifiable(readyShifts),
      warningViolations: List.unmodifiable(warningViolations),
      blockingViolations: List.unmodifiable(blockingViolations),
      auditTrace: List.unmodifiable(evaluation.violations),
    );
  }
}
