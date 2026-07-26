class CalendarEventCandidate {
  const CalendarEventCandidate({
    required this.syncId,
    required this.title,
    required this.start,
    required this.end,
    required this.shouldExist,
    this.description,
    this.colorId,
  });

  final String syncId;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool shouldExist;
  final String? description;
  final String? colorId;

  bool contentEquals(CalendarEventCandidate other) {
    return title == other.title &&
        start == other.start &&
        end == other.end &&
        description == other.description &&
        colorId == other.colorId &&
        shouldExist == other.shouldExist;
  }
}
