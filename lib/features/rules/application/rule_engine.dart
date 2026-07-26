import '../../../domain/entities/employee.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../../../core/validation/rule_evaluator.dart';
import '../domain/rule.dart';
import '../domain/rule_context.dart';
import '../domain/rule_result.dart';
import '../domain/rule_violation.dart';

class RuleEngine {
  RuleEngine({
    Iterable<Rule> rules = const [],
    this.evaluator = const RuleEvaluator(),
  }) {
    final registeredIds = <String>{};
    for (final rule in rules) {
      if (registeredIds.add(rule.id)) {
        registerRule(rule);
      }
    }
  }

  final Map<String, Rule> _rules = {};
  final RuleEvaluator evaluator;

  List<Rule> get rules => List.unmodifiable(_rules.values);

  void registerRule(Rule rule) {
    if (_rules.containsKey(rule.id)) {
      throw ArgumentError.value(rule.id, 'rule.id', 'Rule already registered');
    }
    _rules[rule.id] = rule;
  }

  bool removeRule(String ruleId) => _rules.remove(ruleId) != null;

  RuleResult validateSchedule(Schedule schedule) {
    return _evaluate(RuleContext(schedule: schedule));
  }

  RuleResult validateAssignment(
    ShiftAssignment assignment, {
    required ScheduleDay day,
    Schedule? schedule,
  }) {
    return _evaluate(
      RuleContext(schedule: schedule, day: day, assignment: assignment),
    );
  }

  RuleResult validateEmployee(Employee employee, Schedule schedule) {
    return _evaluate(RuleContext(schedule: schedule, employee: employee));
  }

  RuleResult _evaluate(RuleContext context) {
    final violations = <RuleViolation>[];
    final passedRules = <String>[];
    final evaluations = evaluator.evaluate<Rule, RuleContext, RuleViolation>(
      rules: _rules.values,
      context: context,
      ruleId: (rule) => rule.id,
      evaluateRule: (rule, evaluationContext) =>
          rule.evaluate(evaluationContext),
    );
    for (final evaluation in evaluations) {
      if (evaluation.violations.isEmpty) {
        passedRules.add(_rules[evaluation.ruleId]!.name);
      } else {
        violations.addAll(evaluation.violations);
      }
    }
    return RuleResult(violations: violations, passedRules: passedRules);
  }
}
