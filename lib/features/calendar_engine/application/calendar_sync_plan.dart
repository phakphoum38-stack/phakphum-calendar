import '../domain/calendar_sync_command.dart';
import '../domain/managed_calendar_event.dart';

class CalendarUpdateOperation {
  const CalendarUpdateOperation({required this.eventId, required this.command});

  final String eventId;
  final CalendarSyncCommand command;
}

class CalendarDeleteOperation {
  const CalendarDeleteOperation({
    required this.eventId,
    required this.calendarId,
  });

  final String eventId;
  final String calendarId;
}

class CalendarSyncPlan {
  const CalendarSyncPlan({
    required this.inserts,
    required this.updates,
    required this.deletes,
  });

  final List<CalendarSyncCommand> inserts;
  final List<CalendarUpdateOperation> updates;
  final List<CalendarDeleteOperation> deletes;

  int get operationCount => inserts.length + updates.length + deletes.length;
}
