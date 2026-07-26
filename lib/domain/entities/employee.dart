import 'department.dart';

class Employee {
  const Employee({
    required this.id,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.department,
    required this.position,
    this.active = true,
  });

  final String id;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String nickname;
  final Department department;
  final String position;
  final bool active;

  /// Creates an updated immutable employee record.
  Employee copyWith({
    String? id,
    String? employeeCode,
    String? firstName,
    String? lastName,
    String? nickname,
    Department? department,
    String? position,
    bool? active,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      department: department ?? this.department,
      position: position ?? this.position,
      active: active ?? this.active,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get displayName =>
      nickname.trim().isEmpty ? fullName : '$fullName ($nickname)';

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        employeeCode.toLowerCase().contains(normalized) ||
        firstName.toLowerCase().contains(normalized) ||
        lastName.toLowerCase().contains(normalized) ||
        nickname.toLowerCase().contains(normalized) ||
        position.toLowerCase().contains(normalized);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Employee && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
