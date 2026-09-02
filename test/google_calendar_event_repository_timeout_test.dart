import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';
import 'package:phakphum_calendar/features/calendar_sync/infrastructure/google_calendar_event_repository.dart';

void main() {
  CalendarEventCandidate candidate() {
    return CalendarEventCandidate(
      syncId: 'sync-1',
      title: 'Shift',
      start: DateTime(2026, 9, 1, 8),
      end: DateTime(2026, 9, 1, 16),
      shouldExist: true,
    );
  }

  test('times out list requests', () async {
    final repository = GoogleCalendarEventRepository(
      _DelayedCalendarApiClient(const Duration(milliseconds: 100)),
      calendarId: 'primary',
      requestTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      repository.listManagedEvents(
        timeMin: DateTime(2026, 9, 1),
        timeMax: DateTime(2026, 9, 2),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('times out create, update, and delete requests', () async {
    final repository = GoogleCalendarEventRepository(
      _DelayedCalendarApiClient(const Duration(milliseconds: 100)),
      calendarId: 'primary',
      requestTimeout: const Duration(milliseconds: 10),
    );
    final event = candidate();

    await expectLater(
      repository.createEvent(event),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(
      repository.updateEvent(providerEventId: 'event-1', candidate: event),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(
      repository.deleteEvent(providerEventId: 'event-1'),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('uses a production-safe default request timeout', () {
    expect(
      GoogleCalendarEventRepository.defaultRequestTimeout,
      const Duration(seconds: 20),
    );
  });
}

class _DelayedCalendarApiClient extends MockClient {
  _DelayedCalendarApiClient(this.delay)
      : super((request) async {
          await Future<void>.delayed(delay);
          return http.Response(jsonEncode({'items': []}), 200);
        });

  final Duration delay;
}
