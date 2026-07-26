import 'rule_category.dart';
import 'rule_context.dart';
import 'rule_severity.dart';
import 'rule_violation.dart';

abstract interface class Rule {
  String get id;
  String get name;
  RuleCategory get category;
  RuleSeverity get severity;

  List<RuleViolation> evaluate(RuleContext context);
}
