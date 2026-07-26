import 'package:flutter/material.dart';

import '../../domain/employee.dart';

class EmployeeChip extends StatelessWidget {
  const EmployeeChip({required this.employee, super.key, this.onDeleted});

  final Employee employee;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: const Icon(Icons.person_outline, size: 18),
      label: Text(employee.displayName),
      onDeleted: onDeleted,
      tooltip: '${employee.employeeCode} • ${employee.department.name}',
    );
  }
}
