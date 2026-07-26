import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

import '../domain/calendar_sync_command.dart';
import '../domain/calendar_sync_gateway.dart';
import '../domain/managed_calendar_event.dart';

class GoogleCalendarSyncGateway implements CalendarSyncGateway {
  GoogleCalendarSyncGateway(this._client);

  static const String syncIdKey = 'sceSyncId';

  final http.Client _client;

  @override
  Future<List<ManagedCalendarEvent>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  }) async {
    final api = calendar.CalendarApi(_client);

    final events = await api.events.list(
      calendarId,
      timeMin: timeMin.toUtc(),
      timeMax: timeMax.toUtc(),
      singleEvents: true,
      showDeleted: false,
      maxResults: 2500,
    );

    return (events.items ?? const <calendar.Event>[])
        .where(
          (event) =>
              event.id != null &&
              _syncId(event) != null &&
              event.start?.dateTime != null &&
              event.end?.dateTime != null,
        )
        .map(
          (event) => ManagedCalendarEvent(
            eventId: event.id!,
            syncId: _syncId(event)!,
            title: event.summary ?? '',
            start: event.start!.dateTime!,
            end: event.end!.dateTime!,
            description: event.description,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ManagedCalendarEvent> insert(CalendarSyncCommand command) async {
    final api = calendar.CalendarApi(_client);
    final created = await api.events.insert(
      _toEvent(command),
      command.calendarId,
    );

    return _toManaged(created, command.syncId);
  }

  @override
  Future<ManagedCalendarEvent> update({
    required String eventId,
    required CalendarSyncCommand command,
  }) async {
    final api = calendar.CalendarApi(_client);
    final updated = await api.events.update(
      _toEvent(command),
      command.calendarId,
      eventId,
    );

    return _toManaged(updated, command.syncId);
  }

  @override
  Future<void> delete({
    required String eventId,
    String calendarId = 'primary',
  }) async {
    final api = calendar.CalendarApi(_client);
    await api.events.delete(calendarId, eventId);
  }

  calendar.Event _toEvent(CalendarSyncCommand command) {
    return calendar.Event(
      summary: command.title,
      description: command.description,
      start: calendar.EventDateTime(dateTime: command.start),
      end: calendar.EventDateTime(dateTime: command.end),
      extendedProperties: calendar.EventExtendedProperties(
        private: <String, String>{
          syncIdKey: command.syncId,
          'sourceApp': 'phakphum_shift_calendar',
          'sourceKey': command.syncId,
        },
      ),
    );
  }

  ManagedCalendarEvent _toManaged(calendar.Event event, String fallbackSyncId) {
    return ManagedCalendarEvent(
      eventId: event.id ?? '',
      syncId: _syncId(event) ?? fallbackSyncId,
      title: event.summary ?? '',
      start: event.start?.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      end: event.end?.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      description: event.description,
    );
  }

  String? _syncId(calendar.Event event) {
    final properties = event.extendedProperties?.private;
    final current = properties?[syncIdKey];
    if (current != null && current.isNotEmpty) return current;
    if (properties?['sourceApp'] != 'phakphum_shift_calendar') return null;
    return properties?['sourceKey'];
  }
}
