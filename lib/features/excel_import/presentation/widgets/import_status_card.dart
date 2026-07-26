import 'package:flutter/material.dart';

import '../../domain/import_file.dart';
import '../../domain/worksheet_info.dart';

class ImportStatusCard extends StatelessWidget {
  const ImportStatusCard({
    required this.file,
    required this.worksheetCount,
    this.selectedWorksheet,
    this.loadedRowCount,
    super.key,
  });

  final ImportFile file;
  final int worksheetCount;
  final WorksheetInfo? selectedWorksheet;
  final int? loadedRowCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizeInKilobytes = file.sizeInBytes / 1024;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(
                selectedWorksheet == null ? Icons.description : Icons.check,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sizeInKilobytes.toStringAsFixed(1)} KB'
                    ' • $worksheetCount Worksheet',
                  ),
                  if (selectedWorksheet != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'อ่าน "${selectedWorksheet!.name}" แล้ว'
                      ' ${loadedRowCount ?? 0} แถว',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
