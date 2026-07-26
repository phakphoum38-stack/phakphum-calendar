import 'package:flutter/material.dart';

import '../../domain/rule.dart';
import '../../domain/rule_result.dart';
import '../../../../l10n/l10n.dart';
import '../widgets/rule_card.dart';
import '../widgets/validation_summary_card.dart';
import '../widgets/violation_tile.dart';

class RuleValidationPage extends StatelessWidget {
  const RuleValidationPage({
    required this.result,
    required this.rules,
    super.key,
  });

  final RuleResult result;
  final List<Rule> rules;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.validationTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ValidationSummaryCard(result: result),
          const SizedBox(height: 20),
          if (result.errors.isNotEmpty) ...[
            Text(
              context.l10n.errors,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final violation in result.errors)
                    ViolationTile(violation: violation),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (result.warnings.isNotEmpty) ...[
            Text(
              context.l10n.warnings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final violation in result.warnings)
                    ViolationTile(violation: violation),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            context.l10n.rules,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RuleCard(
                rule: rule,
                violations: result.violations
                    .where((violation) => violation.ruleId == rule.id)
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }
}
