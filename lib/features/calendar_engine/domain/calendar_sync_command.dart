class CalendarSyncCommand {
  const CalendarSyncCommand({
    required this.syncId,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.calendarId = 'primary',
  });

  final String syncId;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String calendarId;
}
