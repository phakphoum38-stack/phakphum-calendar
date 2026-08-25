import '../../../domain/entities/employee.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/shift_type.dart';
import 'coverage_requirement.dart';
import 'department_capacity.dart';
import 'employee_availability.dart';

class GenerationRequest {
  GenerationRequest({
    required this.schedule,
    required this.month,
    required List<Employee> employees,
    required List<ShiftType> shiftTypes,
    required List<CoverageRequirement> coverageRequirements,
    List<EmployeeAvailability> availability = const [],
    List<DepartmentCapacity> departmentCapacities = const [],
    Map<String, String> lockedDutyPointsByEmployeeId = const {},
  }) : employees = List.unmodifiable(employees),
       shiftTypes = List.unmodifiable(shiftTypes),
       coverageRequirements = List.unmodifiable(coverageRequirements),
       availability = List.unmodifiable(availability),
       departmentCapacities = List.unmodifiable(departmentCapacities),
       lockedDutyPointsByEmployeeId = Map.unmodifiable(
         lockedDutyPointsByEmployeeId,
       );

  final Schedule schedule;
  final DateTime month;
  final List<Employee> employees;
  final List<ShiftType> shiftTypes;
  final List<CoverageRequirement> coverageRequirements;
  final List<EmployeeAvailability> availability;
  final List<DepartmentCapacity> departmentCapacities;
  final Map<String, String> lockedDutyPointsByEmployeeId;
}
