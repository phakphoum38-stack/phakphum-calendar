import '../../../domain/entities/shift_assignment.dart';
import '../domain/employee_availability.dart';

class EmployeeAvailabilityService {
  const EmployeeAvailabilityService();

  bool isAvailable({
    required ShiftAssignment assignment,
    required DateTime date,
    required List<EmployeeAvailability> availability,
  }) {
    final matching = availability.where(
      (item) =>
          item.employeeId == assignment.employee.id &&
          _sameDay(item.date, date),
    );
    if (matching.isEmpty) return true;
    return matching.any((item) => item.allows(assignment.shift.id));
  }

  bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
