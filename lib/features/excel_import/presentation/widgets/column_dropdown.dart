import 'package:flutter/material.dart';

import '../controllers/column_mapping_controller.dart';

class ColumnDropdown extends StatelessWidget {
  const ColumnDropdown({
    required this.field,
    required this.availableColumns,
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final DestinationField field;
  final List<String> availableColumns;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('column-${field.name}-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.isRequired ? 'Required *' : 'Optional',
        errorText: errorText,
      ),
      hint: const Text('Select Excel column'),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Not mapped')),
        for (final column in availableColumns)
          DropdownMenuItem(value: column, child: Text(column)),
      ],
      onChanged: onChanged,
    );
  }
}
