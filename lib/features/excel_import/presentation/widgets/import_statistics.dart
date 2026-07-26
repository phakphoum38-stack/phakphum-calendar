import 'package:flutter/material.dart';

import '../../domain/import_summary.dart';
import 'summary_card.dart';

class ImportStatistics extends StatelessWidget {
  const ImportStatistics({required this.summary, super.key});

  final ImportSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 720
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth >= 480
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: SummaryCard(
                label: 'Imported rows',
                value: '${summary.importedRows}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: width,
              child: SummaryCard(
                label: 'Skipped rows',
                value: '${summary.skippedRows}',
                icon: Icons.skip_next_outlined,
                color: colorScheme.secondary,
              ),
            ),
            SizedBox(
              width: width,
              child: SummaryCard(
                label: 'Error rows',
                value: '${summary.errorRows}',
                icon: Icons.error_outline,
                color: colorScheme.error,
              ),
            ),
            SizedBox(
              width: width,
              child: SummaryCard(
                label: 'Errors',
                value: '${summary.errorCount}',
                icon: Icons.report_gmailerrorred,
                color: colorScheme.error,
              ),
            ),
            SizedBox(
              width: width,
              child: SummaryCard(
                label: 'Warnings',
                value: '${summary.warningCount}',
                icon: Icons.warning_amber,
                color: Colors.orange,
              ),
            ),
            SizedBox(
              width: width,
              child: SummaryCard(
                label: 'Success',
                value: '${summary.successPercentage.toStringAsFixed(1)}%',
                icon: Icons.percent,
                color: colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
