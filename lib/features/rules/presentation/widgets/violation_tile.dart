import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/rule_severity.dart';
import '../../domain/rule_violation.dart';

class ViolationTile extends StatelessWidget {
  const ViolationTile({required this.violation, super.key});

  final RuleViolation violation;

  @override
  Widget build(BuildContext context) {
    final isError = violation.severity == RuleSeverity.error;
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;
    final details = [
      if (violation.employeeId != null) 'Employee: ${violation.employeeId}',
      if (violation.date != null)
        'Date: ${DateFormat.yMMMd().format(violation.date!)}',
    ].join(' • ');

    return ListTile(
      leading: Icon(
        isError ? Icons.error_outline : Icons.warning_amber,
        color: color,
      ),
      title: Text(violation.message),
      subtitle: details.isEmpty ? Text(violation.ruleName) : Text(details),
      trailing: Text(
        isError ? 'ERROR' : 'WARNING',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
