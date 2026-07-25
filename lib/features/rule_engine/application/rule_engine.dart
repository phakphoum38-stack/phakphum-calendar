import '../domain/schedule_rule.dart';

class RuleEvaluationResult {
  const RuleEvaluationResult(this.violations);

  final List<RuleViolation> violations;

  bool get hasBlockingViolation =>
      violations.any((item) => item.severity == RuleSeverity.blocking);

  bool get canSync => !hasBlockingViolation;

  int get informationCount =>
      violations.where((item) => item.severity == RuleSeverity.info).length;

  int get warningCount =>
      violations.where((item) => item.severity == RuleSeverity.warning).length;

  int get blockingCount =>
      violations.where((item) => item.severity == RuleSeverity.blocking).length;
}

class RuleEngine {
  RuleEngine(List<ScheduleRule> rules) : rules = List.unmodifiable(rules);

  final List<ScheduleRule> rules;

  RuleEvaluationResult evaluate(List<ScheduledShift> shifts) {
    final violations = <RuleViolation>[];

    for (final rule in rules) {
      violations.addAll(rule.evaluate(List.unmodifiable(shifts)));
    }

    violations.sort((first, second) {
      final severityComparison = _severityPriority(
        second.severity,
      ).compareTo(_severityPriority(first.severity));

      if (severityComparison != 0) {
        return severityComparison;
      }

      final ruleComparison = first.ruleId.compareTo(second.ruleId);

      if (ruleComparison != 0) {
        return ruleComparison;
      }

      return first.shiftIds.join(',').compareTo(second.shiftIds.join(','));
    });

    return RuleEvaluationResult(List.unmodifiable(violations));
  }

  static int _severityPriority(RuleSeverity severity) {
    return switch (severity) {
      RuleSeverity.info => 0,
      RuleSeverity.warning => 1,
      RuleSeverity.blocking => 2,
    };
  }
}
