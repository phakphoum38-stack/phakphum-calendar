import 'rule_severity.dart';
import 'rule_violation.dart';

class RuleResult {
  RuleResult({
    required List<RuleViolation> violations,
    List<String> passedRules = const [],
  }) : violations = List.unmodifiable(violations),
       passedRules = List.unmodifiable(passedRules);

  final List<RuleViolation> violations;
  final List<String> passedRules;

  bool get passed => errors.isEmpty;
  List<RuleViolation> get warnings => violations
      .where((item) => item.severity == RuleSeverity.warning)
      .toList(growable: false);
  List<RuleViolation> get errors => violations
      .where((item) => item.severity == RuleSeverity.error)
      .toList(growable: false);
}
