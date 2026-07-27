import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

import '../domain/calendar_sync_command.dart';
import '../domain/calendar_sync_gateway.dart';
import '../domain/managed_calendar_event.dart';

class GoogleCalendarSyncGateway
    implements CalendarSyncGateway, ComparableCalendarEventGateway {
  GoogleCalendarSyncGateway(this._client);

  static const String syncIdKey = 'sceSyncId';

  final http.Client _client;

  @override
  Future<List<ManagedCalendarEvent>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  }) async {
    return _listEvents(
      timeMin: timeMin,
      timeMax: timeMax,
      calendarId: calendarId,
      managedOnly: true,
    );
  }

  @override
  Future<List<ManagedCalendarEvent>> listComparableLegacyEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  }) {
    return _listEvents(
      timeMin: timeMin,
      timeMax: timeMax,
      calendarId: calendarId,
      managedOnly: false,
    );
  }

  Future<List<ManagedCalendarEvent>> _listEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    required String calendarId,
    required bool managedOnly,
  }) async {
    final api = calendar.CalendarApi(_client);
    final items = <calendar.Event>[];
    String? pageToken;
    do {
      final events = await api.events.list(
        calendarId,
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        maxResults: 2500,
        pageToken: pageToken,
      );
      items.addAll(events.items ?? const <calendar.Event>[]);
      pageToken = events.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return items
        .where(
          (event) =>
              event.id != null &&
              (!managedOnly ||
                  event.extendedProperties?.private?[syncIdKey] != null) &&
              event.start?.dateTime != null &&
              event.end?.dateTime != null &&
              (managedOnly ||
                  event.extendedProperties?.private?[syncIdKey] == null),
        )
        .map(
          (event) => ManagedCalendarEvent(
            eventId: event.id!,
            syncId:
                event.extendedProperties?.private?[syncIdKey] ??
                'legacy:${event.id!}',
            title: event.summary ?? '',
            start: event.start!.dateTime!,
            end: event.end!.dateTime!,
            description: event.description,
            colorId: event.colorId,
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
      colorId: command.colorId,
      start: calendar.EventDateTime(dateTime: command.start),
      end: calendar.EventDateTime(dateTime: command.end),
      extendedProperties: calendar.EventExtendedProperties(
        private: <String, String>{syncIdKey: command.syncId},
      ),
    );
  }

  ManagedCalendarEvent _toManaged(calendar.Event event, String fallbackSyncId) {
    return ManagedCalendarEvent(
      eventId: event.id ?? '',
      syncId: event.extendedProperties?.private?[syncIdKey] ?? fallbackSyncId,
      title: event.summary ?? '',
      start: event.start?.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      end: event.end?.dateTime ?? DateTime.fromMillisecondsSinceEpoch(0),
      description: event.description,
      colorId: event.colorId,
    );
  }
}
