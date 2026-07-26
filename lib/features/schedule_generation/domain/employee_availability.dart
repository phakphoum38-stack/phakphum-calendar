class EmployeeAvailability {
  EmployeeAvailability({
    required this.employeeId,
    required DateTime date,
    this.available = true,
    Set<String> shiftTypeIds = const {},
  }) : date = DateTime(date.year, date.month, date.day),
       shiftTypeIds = Set.unmodifiable(shiftTypeIds);

  final String employeeId;
  final DateTime date;
  final bool available;
  final Set<String> shiftTypeIds;

  bool allows(String shiftTypeId) =>
      available && (shiftTypeIds.isEmpty || shiftTypeIds.contains(shiftTypeId));
}
