import 'package:flutter/material.dart';

class DuplicateWarningCard extends StatelessWidget {
  const DuplicateWarningCard({required this.duplicateColumns, super.key});

  final Set<String> duplicateColumns;

  @override
  Widget build(BuildContext context) {
    if (duplicateColumns.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Duplicate columns: ${duplicateColumns.join(', ')}',
                style: TextStyle(color: colorScheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
