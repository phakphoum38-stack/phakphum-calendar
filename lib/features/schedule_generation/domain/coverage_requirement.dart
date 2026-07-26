class CoverageRequirement {
  CoverageRequirement({
    required this.id,
    required DateTime date,
    required this.departmentId,
    required this.shiftTypeId,
    required this.requiredEmployees,
    this.location,
  }) : assert(requiredEmployees >= 0),
       date = DateTime(date.year, date.month, date.day);

  final String id;
  final DateTime date;
  final String departmentId;
  final String shiftTypeId;
  final int requiredEmployees;
  final String? location;
}
