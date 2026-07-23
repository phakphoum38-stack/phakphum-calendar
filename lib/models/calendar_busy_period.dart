class CalendarBusyPeriod {
  const CalendarBusyPeriod({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.legacyKey,
    this.htmlLink,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String legacyKey;
  final String? htmlLink;
}

class CalendarReadResult {
  const CalendarReadResult({
    required this.sourceKeys,
    required this.busyPeriods,
  });

  final Set<String> sourceKeys;
  final List<CalendarBusyPeriod> busyPeriods;
}
