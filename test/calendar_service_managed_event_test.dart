import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';

void main() {
  test(
    'canonical app events are current entries instead of conflicts',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, contains('/calendars/primary/events'));
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'canonical-event',
                'summary': 'ER ดึก',
                'start': {'dateTime': '2026-08-16T00:00:00+07:00'},
                'end': {'dateTime': '2026-08-16T08:00:00+07:00'},
                'extendedProperties': {
                  'private': {'sceSyncId': 'sce-existing'},
                },
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(client.close);
      final shift = Shift(
        code: 'NER',
        rowLabel: 'ER ดึก',
        assignedName: 'ผู้ใช้งานทดสอบ',
        start: DateTime(2026, 8, 16),
        end: DateTime(2026, 8, 16, 8),
        sheetTitle: 'สิงหาคม 2569',
        cell: 'B2',
        category: ShiftCategory.own,
      );

      final result = await const CalendarService().readCalendar(
        client,
        year: 2026,
        month: 8,
      );

      expect(result.busyPeriods, isEmpty);
      expect(
        result.sourceKeys,
        contains(CalendarService.managedTimeKeyFor(shift)),
      );
      expect(CalendarService.matchesExisting(shift, result.sourceKeys), isTrue);
    },
  );

  test('calendar instants become Bangkok wall-clock values', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'personal-event',
              'summary': 'กิจกรรมส่วนตัว',
              'start': {'dateTime': '2026-08-16T01:00:00Z'},
              'end': {'dateTime': '2026-08-16T02:00:00Z'},
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final result = await const CalendarService().readCalendar(
      client,
      year: 2026,
      month: 8,
    );

    expect(result.busyPeriods.single.start, DateTime(2026, 8, 16, 8));
    expect(result.busyPeriods.single.end, DateTime(2026, 8, 16, 9));
    expect(result.busyPeriods.single.start.isUtc, isFalse);
  });

  test('finds only duplicate events managed by Shift Tools', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'items': [
            {
              'id': 'managed-a',
              'summary': 'รายการ A',
              'start': {'date': '2026-08-10'},
              'end': {'date': '2026-08-11'},
              'extendedProperties': {
                'private': {'sceSyncId': 'sync-1'},
              },
            },
            {
              'id': 'managed-b',
              'summary': 'รายการ A',
              'start': {'dateTime': '2026-08-10T08:00:00+07:00'},
              'end': {'dateTime': '2026-08-10T16:00:00+07:00'},
              'extendedProperties': {
                'private': {'sceSyncId': 'sync-1'},
              },
            },
            {
              'id': 'legacy-a',
              'extendedProperties': {
                'private': {
                  'sourceApp': CalendarService.sourceApp,
                  'sourceKey': 'source-1',
                },
              },
            },
            {
              'id': 'legacy-b',
              'extendedProperties': {
                'private': {
                  'sourceApp': CalendarService.sourceApp,
                  'sourceKey': 'source-1',
                },
              },
            },
            {
              'id': 'personal-copy',
              'summary': 'ชื่อและเวลาเหมือนเวร แต่ไม่มี metadata',
            },
            {
              'id': 'managed-single',
              'extendedProperties': {
                'private': {'sceSyncId': 'sync-2'},
              },
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    addTearDown(client.close);

    final duplicates = await const CalendarService()
        .findManagedDuplicateEventIds(
          client,
          year: 2026,
          month: 8,
          desiredShifts: [
            Shift(
              code: 'A',
              rowLabel: 'รายการ A',
              assignedName: '',
              start: DateTime(2026, 8, 10, 8),
              end: DateTime(2026, 8, 10, 16),
              sheetTitle: 'นำเข้า',
              cell: 'A1',
              category: ShiftCategory.own,
            ),
          ],
        );

    expect(duplicates, ['legacy-b', 'managed-a']);
    expect(duplicates, isNot(contains('personal-copy')));
    expect(duplicates, isNot(contains('managed-single')));
  });
}
