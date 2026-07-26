class ShiftType {
  const ShiftType({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    required this.startTime,
    required this.endTime,
    required this.workingHours,
  }) : assert(workingHours >= 0);

  final String id;
  final String code;
  final String name;
  final int color;
  final Duration startTime;
  final Duration endTime;
  final double workingHours;

  bool get isNightShift =>
      startTime >= const Duration(hours: 18) || endTime <= startTime;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    return normalized.isEmpty ||
        code.toLowerCase().contains(normalized) ||
        name.toLowerCase().contains(normalized);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ShiftType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
