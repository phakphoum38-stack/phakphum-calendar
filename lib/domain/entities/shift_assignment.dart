import 'employee.dart';
import 'shift_type.dart';

class ShiftAssignment {
  const ShiftAssignment({
    required this.employee,
    required this.shift,
    this.remark,
    this.location,
  });

  final Employee employee;
  final ShiftType shift;
  final String? remark;
  final String? location;

  ShiftAssignment copyWith({
    Employee? employee,
    ShiftType? shift,
    String? remark,
    String? location,
    bool clearRemark = false,
    bool clearLocation = false,
  }) {
    return ShiftAssignment(
      employee: employee ?? this.employee,
      shift: shift ?? this.shift,
      remark: clearRemark ? null : remark ?? this.remark,
      location: clearLocation ? null : location ?? this.location,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftAssignment &&
          employee == other.employee &&
          shift == other.shift &&
          remark == other.remark &&
          location == other.location;

  @override
  int get hashCode => Object.hash(employee, shift, remark, location);
}
