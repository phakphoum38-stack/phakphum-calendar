class ManagedCalendarEvent {
  const ManagedCalendarEvent({
    required this.eventId,
    required this.syncId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.colorId,
  });

  final String eventId;
  final String syncId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String? colorId;
}
