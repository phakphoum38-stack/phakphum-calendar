import 'package:flutter/material.dart';

import '../../domain/worksheet_info.dart';

class WorksheetList extends StatelessWidget {
  const WorksheetList({
    required this.worksheets,
    required this.onSelected,
    this.selectedWorksheet,
    this.enabled = true,
    super.key,
  });

  final List<WorksheetInfo> worksheets;
  final WorksheetInfo? selectedWorksheet;
  final ValueChanged<WorksheetInfo> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                'เลือก Worksheet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final worksheet in worksheets)
              ListTile(
                enabled: enabled,
                selected: selectedWorksheet?.name == worksheet.name,
                leading: const Icon(Icons.table_chart_outlined),
                title: Text(worksheet.name),
                subtitle: Text(
                  '${worksheet.rowCount} แถว'
                  ' • ${worksheet.columnCount} คอลัมน์',
                ),
                trailing: selectedWorksheet?.name == worksheet.name
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.chevron_right),
                onTap: enabled ? () => onSelected(worksheet) : null,
              ),
          ],
        ),
      ),
    );
  }
}
