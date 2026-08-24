import '../../../domain/entities/department.dart';
import '../../../domain/entities/employee.dart';
import 'staff_group.dart';

class StaffDirectory {
  StaffDirectory({
    required Map<StaffGroup, List<Employee>> groups,
    Set<String> inChargeEligibleEmployeeIds = const {},
  }) : groups = Map<StaffGroup, List<Employee>>.unmodifiable({
         for (final entry in groups.entries)
           entry.key: List<Employee>.unmodifiable(entry.value),
       }),
       inChargeEligibleEmployeeIds = Set.unmodifiable(
         inChargeEligibleEmployeeIds,
       );

  final Map<StaffGroup, List<Employee>> groups;
  final Set<String> inChargeEligibleEmployeeIds;

  List<Employee> employeesFor(StaffGroup group) =>
      groups[group] ?? const <Employee>[];

  List<Employee> get allEmployees => List.unmodifiable([
    for (final group in StaffGroup.values) ...employeesFor(group),
  ]);

  List<Employee> get inChargeEligible => List.unmodifiable(
    employeesFor(StaffGroup.radiologicTechnologist)
        .where((employee) => inChargeEligibleEmployeeIds.contains(employee.id)),
  );

  static Department departmentFor(StaffGroup group) =>
      Department(id: group.id, code: group.code, name: group.thaiName);
}
