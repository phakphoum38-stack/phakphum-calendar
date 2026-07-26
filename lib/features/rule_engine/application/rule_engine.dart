import '../../../core/validation/rule_evaluator.dart';
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
  const RuleEngine(this.rules, {this.evaluator = const RuleEvaluator()});

  final List<ScheduleRule> rules;
  final RuleEvaluator evaluator;

  RuleEvaluationResult evaluate(List<ScheduledShift> shifts) {
    final violations = <RuleViolation>[];
    final evaluations = evaluator
        .evaluate<ScheduleRule, List<ScheduledShift>, RuleViolation>(
          rules: rules,
          context: shifts,
          ruleId: (rule) => rule.id,
          evaluateRule: (rule, scheduledShifts) =>
              rule.evaluate(scheduledShifts),
        );
    for (final evaluation in evaluations) {
      violations.addAll(evaluation.violations);
    }
    return RuleEvaluationResult(List.unmodifiable(violations));
  }
}
