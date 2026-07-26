class ShiftRecord {
  const ShiftRecord({
    required this.date,
    required this.shift,
    required this.employee,
    required this.rowNumber,
    this.department,
    this.location,
    this.notes,
  });

  final DateTime? date;
  final String shift;
  final String employee;
  final String? department;
  final String? location;
  final String? notes;
  final int rowNumber;
}
