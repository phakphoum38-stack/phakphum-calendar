class CalendarEventCandidate {
  const CalendarEventCandidate({
    required this.syncId,
    required this.title,
    required this.start,
    required this.end,
    required this.shouldExist,
    this.description,
  });

  final String syncId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool shouldExist;
  final String? description;

  bool contentEquals(CalendarEventCandidate other) {
    return title == other.title &&
        start == other.start &&
        end == other.end &&
        description == other.description &&
        shouldExist == other.shouldExist;
  }
}
