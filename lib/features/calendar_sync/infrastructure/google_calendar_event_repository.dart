import 'package:googleapis/calendar/v3.dart' as calendar;

import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../domain/calendar_event_record.dart';
import '../domain/calendar_event_repository.dart';
import 'google_calendar_event_mapper.dart';

class GoogleCalendarEventRepository implements CalendarEventRepository {
  GoogleCalendarEventRepository({
    required this._calendarApi,
    required String calendarId,
    this.requestTimeout = defaultRequestTimeout,
  }) : _calendarId = calendarId.trim(),
       _mapper = const GoogleCalendarEventMapper() {
    if (_calendarId.isEmpty) {
      throw ArgumentError.value(
        calendarId,
        'calendarId',
        'Calendar ID must not be empty.',
      );
    }
  }

  final calendar.CalendarApi _calendarApi;
  final String _calendarId;
  final GoogleCalendarEventMapper _mapper;
  final Duration requestTimeout;

  static const Duration defaultRequestTimeout = Duration(seconds: 20);

  @override
  Future<List<CalendarEventRecord>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  }) async {
    if (!timeMax.isAfter(timeMin)) {
      throw ArgumentError('timeMax must be after timeMin.');
    }

    final records = <CalendarEventRecord>[];
    String? pageToken;

    do {
      final response = await _calendarApi.events.list(
        _calendarId,
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        showDeleted: false,
        privateExtendedProperty: const <String>[
          '${GoogleCalendarEventMapper.managedByKey}='
              '${GoogleCalendarEventMapper.managedByValue}',
        ],
        pageToken: pageToken,
      ).timeout(requestTimeout);

      for (final event in response.items ?? const <calendar.Event>[]) {
        final record = _mapper.fromGoogleEvent(event);

        if (record != null) {
          records.add(record);
        }
      }

      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    records.sort(_compareRecords);

    return List<CalendarEventRecord>.unmodifiable(records);
  }

  @override
  Future<String> createEvent(CalendarEventCandidate candidate) async {
    final request = _mapper.toGoogleEvent(candidate);

    final created = await _calendarApi.events
        .insert(request, _calendarId)
        .timeout(requestTimeout);

    final providerEventId = created.id?.trim();

    if (providerEventId == null || providerEventId.isEmpty) {
      throw StateError(
        'Google Calendar did not return an event ID after creation.',
      );
    }

    return providerEventId;
  }

  @override
  Future<void> updateEvent({
    required String providerEventId,
    required CalendarEventCandidate candidate,
  }) async {
    final normalizedEventId = _requireProviderEventId(providerEventId);

    final request = _mapper.toGoogleEvent(candidate);

    await _calendarApi.events
        .update(request, _calendarId, normalizedEventId)
        .timeout(requestTimeout);
  }

  @override
  Future<void> deleteEvent({required String providerEventId}) async {
    final normalizedEventId = _requireProviderEventId(providerEventId);

    await _calendarApi.events
        .delete(_calendarId, normalizedEventId)
        .timeout(requestTimeout);
  }

  int _compareRecords(CalendarEventRecord left, CalendarEventRecord right) {
    final startComparison = left.candidate.start.compareTo(
      right.candidate.start,
    );

    if (startComparison != 0) {
      return startComparison;
    }

    return left.candidate.syncId.compareTo(right.candidate.syncId);
  }

  String _requireProviderEventId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'providerEventId',
        'Provider event ID must not be empty.',
      );
    }

    return normalized;
  }
}
