import 'calendar_sync_command.dart';
import 'managed_calendar_event.dart';

abstract interface class CalendarSyncGateway {
  Future<List<ManagedCalendarEvent>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  });

  Future<ManagedCalendarEvent> insert(
    CalendarSyncCommand command,
  );

  Future<ManagedCalendarEvent> update({
    required String eventId,
    required CalendarSyncCommand command,
  });

  Future<void> delete({
    required String eventId,
    String calendarId = 'primary',
  });
}
