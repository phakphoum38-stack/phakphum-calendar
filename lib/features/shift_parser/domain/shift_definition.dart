class ShiftDefinition {
  const ShiftDefinition({
    required this.category,
    required this.period,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.endsNextDay,
  });

  final String category;
  final String period;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool endsNextDay;

  DateTime startFor(DateTime date) => DateTime(
        date.year,
        date.month,
        date.day,
        startHour,
        startMinute,
      );

  DateTime endFor(DateTime date) {
    final base = DateTime(
      date.year,
      date.month,
      date.day,
      endHour,
      endMinute,
    );
    return endsNextDay ? base.add(const Duration(days: 1)) : base;
  }
}
