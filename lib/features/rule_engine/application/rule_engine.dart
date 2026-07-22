import '../domain/schedule_rule.dart';

class RuleEvaluationResult {
  const RuleEvaluationResult(this.violations);

  final List<RuleViolation> violations;

  bool get hasBlockingViolation =>
      violations.any((item) => item.severity == RuleSeverity.blocking);

  int get warningCount =>
      violations.where((item) => item.severity == RuleSeverity.warning).length;
}

class RuleEngine {
  const RuleEngine(this.rules);

  final List<ScheduleRule> rules;

  RuleEvaluationResult evaluate(List<ScheduledShift> shifts) {
    final violations = <RuleViolation>[];
    for (final rule in rules) {
      violations.addAll(rule.evaluate(shifts));
    }
    return RuleEvaluationResult(List.unmodifiable(violations));
  }
}
