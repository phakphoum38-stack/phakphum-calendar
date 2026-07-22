import 'package:flutter/foundation.dart';

@immutable
class HospitalOrganization {
  const HospitalOrganization({
    required this.id,
    required this.name,
    required this.departments,
    this.isActive = true,
  });

  final String id;
  final String name;
  final List<HospitalDepartment> departments;
  final bool isActive;

  HospitalDepartment? departmentById(String departmentId) {
    for (final department in departments) {
      if (department.id == departmentId) return department;
    }
    return null;
  }
}

@immutable
class HospitalDepartment {
  const HospitalDepartment({
    required this.id,
    required this.organizationId,
    required this.name,
    this.code,
    this.isActive = true,
  });

  final String id;
  final String organizationId;
  final String name;
  final String? code;
  final bool isActive;
}
