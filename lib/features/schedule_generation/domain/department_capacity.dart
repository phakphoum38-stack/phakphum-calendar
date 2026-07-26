class DepartmentCapacity {
  DepartmentCapacity({
    required this.departmentId,
    required DateTime date,
    required this.maximumAssignments,
  }) : assert(maximumAssignments >= 0),
       date = DateTime(date.year, date.month, date.day);

  final String departmentId;
  final DateTime date;
  final int maximumAssignments;
}
