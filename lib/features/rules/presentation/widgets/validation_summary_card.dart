import 'package:flutter/material.dart';

import '../../domain/rule_result.dart';

class ValidationSummaryCard extends StatelessWidget {
  const ValidationSummaryCard({required this.result, super.key});

  final RuleResult result;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _SummaryValue(
              icon: result.passed ? Icons.check_circle : Icons.cancel,
              label: result.passed ? 'Passed' : 'Action required',
              color: result.passed ? colorScheme.primary : colorScheme.error,
            ),
            _SummaryValue(
              icon: Icons.error_outline,
              label: '${result.errors.length} Errors',
              color: colorScheme.error,
            ),
            _SummaryValue(
              icon: Icons.warning_amber,
              label: '${result.warnings.length} Warnings',
              color: colorScheme.tertiary,
            ),
            _SummaryValue(
              icon: Icons.rule,
              label: '${result.passedRules.length} Passed rules',
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
