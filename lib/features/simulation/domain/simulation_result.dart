import '../../rule_engine/domain/schedule_rule.dart';

class SimulationResult {
  const SimulationResult({
    required this.totalShiftCount,
    required this.readyShifts,
    required this.warningViolations,
    required this.blockingViolations,
    required this.auditTrace,
  });

  final int totalShiftCount;
  final List<ScheduledShift> readyShifts;
  final List<RuleViolation> warningViolations;
  final List<RuleViolation> blockingViolations;
  final List<RuleViolation> auditTrace;

  bool get canSync => blockingViolations.isEmpty;

  int get readyCount => readyShifts.length;

  int get warningCount => warningViolations.length;

  int get blockedCount => blockingViolations.length;
}
