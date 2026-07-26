import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/schedule_controller.dart';

class ScheduleFilters extends StatefulWidget {
  const ScheduleFilters({required this.controller, super.key});

  final ScheduleController controller;

  @override
  State<ScheduleFilters> createState() => _ScheduleFiltersState();
}

class _ScheduleFiltersState extends State<ScheduleFilters> {
  late final TextEditingController staffController = TextEditingController(
    text: widget.controller.staffNameQuery,
  );

  @override
  void didUpdateWidget(covariant ScheduleFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.controller.staffNameQuery;
    if (staffController.text != query) {
      staffController.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    staffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: staffController,
            onChanged: controller.filterStaffName,
            decoration: const InputDecoration(
              labelText: 'Staff name',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        _FilterDropdown(
          label: 'Role / position',
          value: controller.positionQuery.isEmpty
              ? null
              : controller.positionQuery,
          items: {
            for (final position in controller.positions) position: position,
          },
          onChanged: controller.filterPosition,
        ),
        _FilterDropdown(
          label: 'Department',
          value: controller.selectedDepartmentId,
          items: {
            for (final item in controller.departments) item.id: item.name,
          },
          onChanged: controller.filterDepartment,
        ),
        _FilterDropdown(
          label: 'Employee',
          value: controller.selectedEmployeeId,
          items: {
            for (final item in controller.employeeResults)
              item.id: item.displayName,
          },
          onChanged: controller.filterEmployee,
        ),
        _FilterDropdown(
          label: 'Shift',
          value: controller.selectedShiftId,
          items: {
            for (final item in controller.shiftResults)
              item.id: '${item.code} — ${item.name}',
          },
          onChanged: controller.filterShift,
        ),
        ActionChip(
          avatar: const Icon(Icons.calendar_today_outlined, size: 18),
          label: Text(
            controller.selectedDate == null
                ? 'Any date'
                : DateFormat.yMMMd().format(controller.selectedDate!),
          ),
          onPressed: () => _selectDate(context),
        ),
        TextButton.icon(
          onPressed: controller.hasActiveFilters
              ? controller.clearFilters
              : null,
          icon: const Icon(Icons.filter_alt_off),
          label: const Text('Clear all filters'),
        ),
        if (controller.hasActiveFilters)
          for (final label in controller.activeFilterLabels)
            Chip(
              avatar: const Icon(Icons.filter_alt, size: 16),
              label: Text(label),
            ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final controller = widget.controller;
    final selected = await showDatePicker(
      context: context,
      firstDate: controller.currentMonth,
      lastDate: DateTime(
        controller.currentMonth.year,
        controller.currentMonth.month + 1,
        0,
      ),
      initialDate: controller.selectedDate ?? controller.currentMonth,
    );
    if (selected != null) {
      controller.filterDate(selected);
    }
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.containsKey(value) ? value : null;
    return SizedBox(
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: effectiveValue,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          for (final entry in items.entries)
            DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
