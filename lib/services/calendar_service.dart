import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

import '../models/calendar_busy_period.dart';
import '../models/shift.dart';
import 'google_api_client.dart';

class CalendarService {
  const CalendarService();

  static const sourceApp = 'phakphum_shift_calendar';
  static const timeZone = 'Asia/Bangkok';

  Future<Set<String>> existingSourceKeys(
    GoogleApiClient client, {
    required int year,
    required int month,
  }) async {
    return (await readCalendar(client, year: year, month: month)).sourceKeys;
  }

  Future<CalendarReadResult> readCalendar(
    GoogleApiClient client, {
    required int year,
    required int month,
  }) async {
    final api = calendar.CalendarApi(client);
    final start = DateTime.utc(
      year,
      month,
      1,
    ).subtract(const Duration(hours: 7));
    final end = DateTime.utc(
      year,
      month + 1,
      1,
    ).subtract(const Duration(hours: 7));
    final sourceKeys = <String>{};
    final busyPeriods = <CalendarBusyPeriod>[];
    String? pageToken;
    do {
      final page = await api.events.list(
        'primary',
        timeMin: start,
        timeMax: end,
        singleEvents: true,
        showDeleted: false,
        maxResults: 2500,
        pageToken: pageToken,
      );
      for (final event in page.items ?? const <calendar.Event>[]) {
        final privateProperties = event.extendedProperties?.private;
        final isManaged = privateProperties?['sourceApp'] == sourceApp;
        if (isManaged && (privateProperties?['sourceKey'] ?? '').isNotEmpty) {
          sourceKeys.add(privateProperties!['sourceKey']!);
        }
        final startTime = event.start?.dateTime;
        final summary = event.summary;
        if (startTime != null && summary != null && summary.isNotEmpty) {
          final bangkokWall = startTime.toUtc().add(const Duration(hours: 7));
          sourceKeys.add(_legacyKey(summary, bangkokWall));
        }
        if (isManaged || event.transparency == 'transparent') continue;
        final wallStart = _wallTime(event.start);
        final wallEnd = _wallTime(event.end);
        if (wallStart == null ||
            wallEnd == null ||
            !wallEnd.isAfter(wallStart)) {
          continue;
        }
        busyPeriods.add(
          CalendarBusyPeriod(
            id: event.id ?? '${event.iCalUID ?? 'calendar'}|$wallStart',
            title: (summary ?? '').trim().isEmpty
                ? 'กิจกรรมไม่มีชื่อ'
                : summary!,
            start: wallStart,
            end: wallEnd,
            legacyKey: _legacyKey(summary ?? '', wallStart),
          ),
        );
      }
      pageToken = page.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);
    return CalendarReadResult(sourceKeys: sourceKeys, busyPeriods: busyPeriods);
  }

  Future<int> insertMissing(
    GoogleApiClient client,
    List<Shift> shifts,
    Set<String> existingKeys,
  ) async {
    final api = calendar.CalendarApi(client);
    var inserted = 0;
    for (final shift in shifts) {
      final key = keyFor(shift);
      if (shift.excluded || matchesExisting(shift, existingKeys)) continue;
      final event = calendar.Event(
        summary: summaryFor(shift),
        description:
            '${shift.generated ? 'สร้างอัตโนมัติเป็นเวรออฟหลังเวรดึก\n' : 'สร้างจากตารางเวร (อ่านอย่างเดียว)\n'}'
            'ชื่อเวรจากชีต: ${shift.rowLabel}\n'
            'ผู้ปฏิบัติงานในตาราง: ${shift.assignedName}\n'
            '${shift.sourceColorHex == null ? '' : 'สีเซลล์ต้นฉบับ: ${shift.sourceColorHex}\n'}'
            'ชีต: ${shift.sheetTitle} เซลล์ ${shift.cell}\n'
            'ประเภท: ${shift.category.label}',
        colorId: shift.category.googleColorId,
        start: calendar.EventDateTime(
          dateTime: _bangkokInstant(shift.start),
          timeZone: timeZone,
        ),
        end: calendar.EventDateTime(
          dateTime: _bangkokInstant(shift.end),
          timeZone: timeZone,
        ),
        transparency: 'opaque',
        extendedProperties: calendar.EventExtendedProperties(
          private: {'sourceApp': sourceApp, 'sourceKey': key},
        ),
      );
      await api.events.insert(event, 'primary', sendUpdates: 'none');
      existingKeys.add(key);
      existingKeys.add(legacyKeyFor(shift));
      existingKeys.add(displayLegacyKeyFor(shift));
      inserted++;
    }
    return inserted;
  }

  static String keyFor(Shift shift) =>
      sha256.convert(utf8.encode(shift.sourceKey)).toString().substring(0, 32);

  static String legacyKeyFor(Shift shift) =>
      _legacyKey(shift.code, shift.start);

  static String summaryFor(Shift shift) => shift.displayName;

  static String displayLegacyKeyFor(Shift shift) =>
      _legacyKey(summaryFor(shift), shift.start);

  static bool matchesLegacyEvent(Shift shift, String legacyKey) =>
      legacyKey == legacyKeyFor(shift) ||
      legacyKey == displayLegacyKeyFor(shift);

  static bool matchesExisting(Shift shift, Set<String> keys) =>
      keys.contains(keyFor(shift)) ||
      keys.contains(legacyKeyFor(shift)) ||
      keys.contains(displayLegacyKeyFor(shift));

  static String _legacyKey(String summary, DateTime wallTime) =>
      'legacy|$summary|${wallTime.year.toString().padLeft(4, '0')}-'
      '${wallTime.month.toString().padLeft(2, '0')}-'
      '${wallTime.day.toString().padLeft(2, '0')}T'
      '${wallTime.hour.toString().padLeft(2, '0')}:'
      '${wallTime.minute.toString().padLeft(2, '0')}';

  DateTime? _wallTime(calendar.EventDateTime? value) {
    final instant = value?.dateTime;
    if (instant != null) {
      return instant.toUtc().add(const Duration(hours: 7));
    }
    final date = value?.date;
    return date == null ? null : DateTime(date.year, date.month, date.day);
  }

  DateTime _bangkokInstant(DateTime wallTime) => DateTime.utc(
    wallTime.year,
    wallTime.month,
    wallTime.day,
    wallTime.hour - 7,
    wallTime.minute,
  );
}
