import 'rule_category.dart';
import 'rule_severity.dart';

class RuleViolation {
  const RuleViolation({
    required this.ruleId,
    required this.ruleName,
    required this.message,
    required this.severity,
    this.employeeId,
    this.date,
    this.category = RuleCategory.custom,
  });

  final String ruleId;
  final String ruleName;
  final String? employeeId;
  final DateTime? date;
  final String message;
  final RuleSeverity severity;
  final RuleCategory category;
}
