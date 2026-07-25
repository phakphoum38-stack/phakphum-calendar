import 'package:googleapis/calendar/v3.dart' as calendar;

import '../domain/calendar_event_record.dart';
import '../domain/calendar_event_repository.dart';
import 'google_calendar_event_mapper.dart';

class GoogleCalendarEventRepository implements CalendarEventRepository {
  GoogleCalendarEventRepository({
    required this._calendarApi,
    required String calendarId,
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
      );

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

  int _compareRecords(CalendarEventRecord left, CalendarEventRecord right) {
    final startComparison = left.candidate.start.compareTo(
      right.candidate.start,
    );

    if (startComparison != 0) {
      return startComparison;
    }

    return left.candidate.syncId.compareTo(right.candidate.syncId);
  }
}
