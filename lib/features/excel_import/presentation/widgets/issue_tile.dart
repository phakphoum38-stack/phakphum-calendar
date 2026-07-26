import 'package:flutter/material.dart';

import '../../domain/import_issue.dart';

class IssueTile extends StatelessWidget {
  const IssueTile({required this.issue, super.key});

  final ImportIssue issue;

  @override
  Widget build(BuildContext context) {
    final isError = issue.severity == ImportIssueSeverity.error;
    final color = isError ? Theme.of(context).colorScheme.error : Colors.orange;
    return ListTile(
      leading: Icon(
        isError ? Icons.error_outline : Icons.warning_amber,
        color: color,
      ),
      title: Text(issue.message),
      subtitle: Text('Row ${issue.rowNumber} • Column ${issue.column}'),
      trailing: Text(
        issue.severity.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
