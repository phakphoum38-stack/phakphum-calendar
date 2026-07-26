/// The result produced by one rule in a [RuleEvaluator] pass.
final class RuleEvaluation<TViolation> {
  /// Creates an immutable per-rule evaluation result.
  RuleEvaluation({
    required this.ruleId,
    required Iterable<TViolation> violations,
  }) : violations = List.unmodifiable(violations);

  /// The stable identifier of the evaluated rule.
  final String ruleId;

  /// Violations returned by the rule.
  final List<TViolation> violations;
}

/// Executes independent rules once, in registration order.
///
/// Feature-specific rule engines retain responsibility for their public result
/// types. This evaluator owns the shared execution guarantees: deterministic
/// ordering and de-duplication by stable rule identifier.
final class RuleEvaluator {
  /// Creates the canonical rule evaluation pipeline.
  const RuleEvaluator();

  /// Evaluates each unique rule and returns its individual result.
  List<RuleEvaluation<TViolation>> evaluate<TRule, TContext, TViolation>({
    required Iterable<TRule> rules,
    required TContext context,
    required String Function(TRule rule) ruleId,
    required Iterable<TViolation> Function(TRule rule, TContext context)
    evaluateRule,
  }) {
    final evaluatedIds = <String>{};
    final evaluations = <RuleEvaluation<TViolation>>[];
    for (final rule in rules) {
      final id = ruleId(rule);
      if (!evaluatedIds.add(id)) {
        continue;
      }
      evaluations.add(
        RuleEvaluation<TViolation>(
          ruleId: id,
          violations: evaluateRule(rule, context),
        ),
      );
    }
    return List.unmodifiable(evaluations);
  }
}
