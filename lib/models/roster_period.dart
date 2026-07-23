class RosterPeriod {
  const RosterPeriod({required this.year, required this.month})
    : assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is RosterPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
