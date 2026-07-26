import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:phakphum_calendar/features/calendar_sync/infrastructure/google_calendar_event_mapper.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';

void main() {
  const mapper = GoogleCalendarEventMapper();

  final start = DateTime.utc(2026, 7, 26, 8);
  final end = DateTime.utc(2026, 7, 26, 16);

  group('GoogleCalendarEventMapper.fromGoogleEvent', () {
    test('maps a valid Google Calendar event', () {
      final event = calendar.Event(
        id: 'google-event-001',
        summary: 'เวรเช้า',
        description: 'แผนกรังสีวิทยา',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-001',
            GoogleCalendarEventMapper.managedByKey:
                GoogleCalendarEventMapper.managedByValue,
          },
        ),
      );

      final record = mapper.fromGoogleEvent(event);

      expect(record, isNotNull);
      expect(record!.providerEventId, 'google-event-001');
      expect(record.candidate.syncId, 'shift-001');
      expect(record.candidate.title, 'เวรเช้า');
      expect(record.candidate.start, start);
      expect(record.candidate.end, end);
      expect(record.candidate.description, 'แผนกรังสีวิทยา');
      expect(record.candidate.shouldExist, isTrue);
    });

    test('trims event ID, sync ID, title, and description', () {
      final event = calendar.Event(
        id: '  google-event-002  ',
        summary: '  เวรดึก  ',
        description: '  CT-IPD  ',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: '  shift-002  ',
          },
        ),
      );

      final record = mapper.fromGoogleEvent(event);

      expect(record, isNotNull);
      expect(record!.providerEventId, 'google-event-002');
      expect(record.candidate.syncId, 'shift-002');
      expect(record.candidate.title, 'เวรดึก');
      expect(record.candidate.description, 'CT-IPD');
    });

    test('normalizes an empty description to null', () {
      final event = calendar.Event(
        id: 'google-event-003',
        summary: 'GEN',
        description: '   ',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-003',
          },
        ),
      );

      final record = mapper.fromGoogleEvent(event);

      expect(record, isNotNull);
      expect(record!.candidate.description, isNull);
    });

    test('returns null when Google event ID is missing', () {
      final event = calendar.Event(
        summary: 'เวรเช้า',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-004',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when Google event ID is empty', () {
      final event = calendar.Event(
        id: '   ',
        summary: 'เวรเช้า',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-005',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when sync ID is missing', () {
      final event = calendar.Event(
        id: 'google-event-006',
        summary: 'เวรบ่าย',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when sync ID is empty', () {
      final event = calendar.Event(
        id: 'google-event-007',
        summary: 'เวรบ่าย',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{GoogleCalendarEventMapper.syncIdKey: '   '},
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when title is missing', () {
      final event = calendar.Event(
        id: 'google-event-008',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-008',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when title is empty', () {
      final event = calendar.Event(
        id: 'google-event-009',
        summary: '   ',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-009',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when start dateTime is missing', () {
      final event = calendar.Event(
        id: 'google-event-010',
        summary: 'เวรดึก',
        start: calendar.EventDateTime(),
        end: calendar.EventDateTime(dateTime: end),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-010',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when end dateTime is missing', () {
      final event = calendar.Event(
        id: 'google-event-011',
        summary: 'เวรดึก',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-011',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null for an all-day event', () {
      final event = calendar.Event(
        id: 'google-event-012',
        summary: 'วันหยุด',
        start: calendar.EventDateTime(date: DateTime.utc(2026, 7, 26)),
        end: calendar.EventDateTime(date: DateTime.utc(2026, 7, 27)),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-012',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when end equals start', () {
      final event = calendar.Event(
        id: 'google-event-013',
        summary: 'IPD',
        start: calendar.EventDateTime(dateTime: start),
        end: calendar.EventDateTime(dateTime: start),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-013',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });

    test('returns null when end is before start', () {
      final event = calendar.Event(
        id: 'google-event-014',
        summary: 'ER',
        start: calendar.EventDateTime(dateTime: end),
        end: calendar.EventDateTime(dateTime: start),
        extendedProperties: calendar.EventExtendedProperties(
          private: <String, String>{
            GoogleCalendarEventMapper.syncIdKey: 'shift-014',
          },
        ),
      );

      expect(mapper.fromGoogleEvent(event), isNull);
    });
  });

  group('GoogleCalendarEventMapper.toGoogleEvent', () {
    test('maps a candidate to a Google Calendar event', () {
      final candidate = CalendarEventCandidate(
        syncId: 'shift-101',
        title: 'CT-ER',
        start: start,
        end: end,
        shouldExist: true,
        description: 'ชั้น 14',
      );

      final event = mapper.toGoogleEvent(candidate);

      expect(event.summary, 'CT-ER');
      expect(event.description, 'ชั้น 14');
      expect(event.start?.dateTime, start);
      expect(event.end?.dateTime, end);
      expect(
        event.extendedProperties?.private?[GoogleCalendarEventMapper.syncIdKey],
        'shift-101',
      );
      expect(
        event.extendedProperties?.private?[GoogleCalendarEventMapper
            .managedByKey],
        GoogleCalendarEventMapper.managedByValue,
      );
    });

    test('supports a null description', () {
      final candidate = CalendarEventCandidate(
        syncId: 'shift-102',
        title: 'GEN',
        start: start,
        end: end,
        shouldExist: true,
      );

      final event = mapper.toGoogleEvent(candidate);

      expect(event.description, isNull);
    });

    test('always writes ownership metadata', () {
      final candidate = CalendarEventCandidate(
        syncId: 'shift-103',
        title: 'IPD',
        start: start,
        end: end,
        shouldExist: true,
      );

      final event = mapper.toGoogleEvent(candidate);
      final privateProperties = event.extendedProperties?.private;

      expect(privateProperties, isNotNull);
      expect(privateProperties, hasLength(2));
      expect(
        privateProperties?[GoogleCalendarEventMapper.syncIdKey],
        'shift-103',
      );
      expect(
        privateProperties?[GoogleCalendarEventMapper.managedByKey],
        GoogleCalendarEventMapper.managedByValue,
      );
    });
  });
}
