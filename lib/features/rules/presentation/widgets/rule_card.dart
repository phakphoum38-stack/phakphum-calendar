import 'package:flutter/material.dart';

import '../../domain/rule.dart';
import '../../domain/rule_violation.dart';

class RuleCard extends StatelessWidget {
  const RuleCard({required this.rule, required this.violations, super.key});

  final Rule rule;
  final List<RuleViolation> violations;

  @override
  Widget build(BuildContext context) {
    final passed = violations.isEmpty;
    return Card(
      child: ListTile(
        leading: Icon(
          passed ? Icons.check_circle_outline : Icons.rule,
          color: passed
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(rule.name),
        subtitle: Text(rule.category.name),
        trailing: Text(passed ? 'Passed' : '${violations.length} violations'),
      ),
    );
  }
}
