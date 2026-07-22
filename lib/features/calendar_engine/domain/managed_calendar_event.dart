class ManagedCalendarEvent {
  const ManagedCalendarEvent({
    required this.eventId,
    required this.syncId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });

  final String eventId;
  final String syncId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
}
