import 'package:flutter/material.dart';

import '../../../../domain/entities/schedule.dart';
import '../../../../l10n/l10n.dart';
import '../controllers/employee_directory_controller.dart';

/// Responsive employee directory backed by the canonical schedule.
class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({
    required this.schedule,
    this.controllerFactory,
    super.key,
  });

  final Schedule schedule;
  final EmployeeDirectoryController Function(Schedule schedule)?
  controllerFactory;

  @override
  State<EmployeeDirectoryPage> createState() => _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  late final EmployeeDirectoryController controller =
      widget.controllerFactory?.call(widget.schedule) ??
      EmployeeDirectoryController(schedule: widget.schedule);
  final searchController = TextEditingController();

  @override
  void didUpdateWidget(covariant EmployeeDirectoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    controller.updateSchedule(widget.schedule);
  }

  @override
  void dispose() {
    searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final employees = controller.employees;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n.employees,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(context.l10n.employeeDirectoryDescription),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: TextField(
                  controller: searchController,
                  onChanged: controller.updateQuery,
                  decoration: InputDecoration(
                    labelText: context.l10n.searchEmployees,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.l10n.clear,
                            onPressed: () {
                              searchController.clear();
                              controller.updateQuery('');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                ),
              ),
              DropdownButton<String?>(
                value: controller.departmentId,
                hint: Text(context.l10n.allDepartments),
                onChanged: controller.updateDepartment,
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.l10n.allDepartments),
                  ),
                  for (final id in controller.departmentIds)
                    DropdownMenuItem(value: id, child: Text(id)),
                ],
              ),
              FilterChip(
                selected: controller.activeOnly,
                onSelected: controller.updateActiveOnly,
                label: Text(context.l10n.activeEmployeesOnly),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (employees.isEmpty)
            _EmployeeEmptyState(hasFilters: controller.query.isNotEmpty)
          else
            Card(
              child: Column(
                children: [
                  for (var index = 0; index < employees.length; index++) ...[
                    ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          employees[index].displayName.characters.firstOrNull ??
                              '?',
                        ),
                      ),
                      title: Text(employees[index].displayName),
                      subtitle: Text(
                        [
                          employees[index].employeeCode,
                          employees[index].position,
                          employees[index].department.name,
                        ].where((value) => value.trim().isNotEmpty).join(' • '),
                      ),
                      trailing: employees[index].active
                          ? const Icon(Icons.check_circle_outline)
                          : const Icon(Icons.block_outlined),
                    ),
                    if (index != employees.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _EmployeeEmptyState extends StatelessWidget {
  const _EmployeeEmptyState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.groups_outlined, size: 52),
          const SizedBox(height: 12),
          Text(
            hasFilters
                ? context.l10n.noEmployeesMatch
                : context.l10n.noEmployeesInSchedule,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
