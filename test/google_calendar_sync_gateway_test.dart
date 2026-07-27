import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:phakphum_calendar/features/calendar_engine/infrastructure/google_calendar_sync_gateway.dart';

void main() {
  test(
    'filters managed and legacy events locally without an invalid query',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'managed-event',
                'summary': 'GEN เช้า',
                'start': {'dateTime': '2026-08-01T07:30:00+07:00'},
                'end': {'dateTime': '2026-08-01T12:00:00+07:00'},
                'extendedProperties': {
                  'private': {'sceSyncId': 'sce-managed'},
                },
              },
              {
                'id': 'legacy-event',
                'summary': 'ER ดึก',
                'start': {'dateTime': '2026-08-16T00:00:00+07:00'},
                'end': {'dateTime': '2026-08-16T08:00:00+07:00'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final gateway = GoogleCalendarSyncGateway(client);

      final managed = await gateway.listManagedEvents(
        timeMin: DateTime(2026, 8),
        timeMax: DateTime(2026, 9),
      );
      final legacy = await gateway.listComparableLegacyEvents(
        timeMin: DateTime(2026, 8),
        timeMax: DateTime(2026, 9),
      );

      expect(managed.map((event) => event.eventId), ['managed-event']);
      expect(legacy.map((event) => event.eventId), ['legacy-event']);
      expect(
        requests.every(
          (request) => !request.url.queryParameters.containsKey(
            'privateExtendedProperty',
          ),
        ),
        isTrue,
      );
    },
  );
}
