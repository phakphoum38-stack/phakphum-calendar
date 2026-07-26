import 'package:flutter/material.dart';

import '../../domain/column_mapping.dart';
import '../../../../l10n/l10n.dart';
import '../controllers/column_mapping_controller.dart';
import '../widgets/column_dropdown.dart';
import '../widgets/duplicate_warning_card.dart';
import '../widgets/mapping_card.dart';
import '../widgets/validation_banner.dart';

class ColumnMappingPage extends StatelessWidget {
  const ColumnMappingPage({required this.controller, this.onNext, super.key});

  final ColumnMappingController controller;
  final ValueChanged<ColumnMapping>? onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.columnMapping)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.l10n.mapExcelColumns,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(context.l10n.requiredMappingHelp),
                      const SizedBox(height: 20),
                      DuplicateWarningCard(
                        duplicateColumns: controller.duplicateColumns,
                      ),
                      if (controller.duplicateColumns.isNotEmpty)
                        const SizedBox(height: 12),
                      ValidationBanner(errors: controller.errors),
                      if (controller.errors.isNotEmpty)
                        const SizedBox(height: 12),
                      for (final field in DestinationField.values) ...[
                        MappingCard(
                          title: field.label,
                          child: ColumnDropdown(
                            field: field,
                            availableColumns: controller.availableColumns,
                            value: controller.valueFor(field),
                            errorText: controller.errorFor(field),
                            onChanged: (column) =>
                                controller.updateMapping(field, column),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: controller.resetMapping,
                            icon: const Icon(Icons.restart_alt),
                            label: Text(context.l10n.reset),
                          ),
                          FilledButton.icon(
                            onPressed: () => _continue(context),
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(context.l10n.next),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _continue(BuildContext context) {
    if (!controller.validateMapping()) return;
    final callback = onNext;
    if (callback != null) {
      callback(controller.mapping);
      return;
    }
    Navigator.of(context).pop(controller.mapping);
  }
}
