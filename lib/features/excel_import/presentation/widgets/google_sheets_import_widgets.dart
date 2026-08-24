import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../services/drive_ownership_service.dart';
import '../../domain/google_sheets_import_info.dart';
import '../../domain/worksheet_info.dart';

/// Dialog that lets the user choose a Google Sheet owned by the active account.
class OwnedGoogleSheetPickerDialog extends StatelessWidget {
  const OwnedGoogleSheetPickerDialog({required this.sheets, super.key});

  final List<RecentOwnedSheet> sheets;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.chooseGoogleSheet),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.ownedGoogleSheetsOnly),
            const SizedBox(height: 12),
            Flexible(
              child: sheets.isEmpty
                  ? Center(child: Text(context.l10n.noOwnedGoogleSheets))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: sheets.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sheet = sheets[index];
                        return ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: Text(sheet.name),
                          subtitle: sheet.modifiedAt == null
                              ? null
                              : Text(
                                  MaterialLocalizations.of(context)
                                      .formatShortDate(
                                        sheet.modifiedAt!.toLocal(),
                                      ),
                                ),
                          onTap: () => Navigator.pop(context, sheet),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
      ],
    );
  }
}

/// Displays metadata and the current preview state for a Google spreadsheet.
class GoogleSheetsStatusCard extends StatelessWidget {
  const GoogleSheetsStatusCard({
    required this.info,
    required this.selectedWorksheet,
    required this.loadedRowCount,
    super.key,
  });

  final GoogleSheetsImportInfo info;
  final WorksheetInfo? selectedWorksheet;
  final int loadedRowCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info.title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('${info.worksheetCount} worksheets'),
            if (selectedWorksheet != null)
              Text(
                '${selectedWorksheet!.name} • '
                '$loadedRowCount preview rows',
              ),
          ],
        ),
      ),
    );
  }
}

/// Displays a controlled Google Sheets import error.
class GoogleSheetsErrorCard extends StatelessWidget {
  const GoogleSheetsErrorCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }
}
