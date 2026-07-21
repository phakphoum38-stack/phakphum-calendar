import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/app_settings.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/models/tool_definition.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';
import 'package:phakphum_calendar/services/drive_archive_service.dart';
import 'package:phakphum_calendar/services/google_auth_service.dart';
import 'package:phakphum_calendar/services/settings_service.dart';
import 'package:phakphum_calendar/services/sheets_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('validates Google Web OAuth client IDs', () {
    expect(
      GoogleAuthService.isValidWebClientId(
        '123456789012-abcDEF_123.apps.googleusercontent.com',
      ),
      isTrue,
    );
    expect(GoogleAuthService.isValidWebClientId('YOUR_WEB_CLIENT_ID'), isFalse);
    expect(
      GoogleAuthService.isValidWebClientId('123.apps.googleusercontent.com'),
      isFalse,
    );
  });

  test('requests only read-only scopes during initial Google access', () {
    expect(
      GoogleAuthService.readAccessScopes,
      containsAll(<String>[
        'https://www.googleapis.com/auth/spreadsheets.readonly',
        'https://www.googleapis.com/auth/calendar.events.readonly',
      ]),
    );
    expect(
      GoogleAuthService.readAccessScopes,
      isNot(contains('https://www.googleapis.com/auth/spreadsheets')),
    );
    expect(
      GoogleAuthService.readAccessScopes,
      isNot(contains('https://www.googleapis.com/auth/calendar.events')),
    );
    expect(
      GoogleAuthService.readAccessScopes,
      isNot(contains('https://www.googleapis.com/auth/drive')),
    );
  });

  test('tool catalog uses unique HTTPS links and safe default pins', () {
    expect(
      toolCatalog.map((tool) => tool.id).toSet(),
      hasLength(toolCatalog.length),
    );
    expect(toolCatalog.every((tool) => tool.uri.scheme == 'https'), isTrue);
    expect(defaultPinnedToolIds.every((id) => toolById(id) != null), isTrue);
    expect(toolById('gmail')!.usesGoogleAccountChooser, isTrue);
    expect(toolById('vscode')!.url, 'https://vscode.dev/');
  });

  test('persists only known pinned tool IDs on the current device', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = SettingsService();

    expect(await service.loadPinnedToolIds(), defaultPinnedToolIds);
    await service.savePinnedToolIds(<String>{'gmail', 'vscode', 'unknown'});

    expect(await service.loadPinnedToolIds(), <String>{'gmail', 'vscode'});
  });

  test('keeps the web OAuth client ID in app settings copies', () {
    final settings = AppSettings.defaults().copyWith(
      googleWebClientId: '123456789012-abcDEF_123.apps.googleusercontent.com',
    );

    expect(
      settings.copyWith(month: 9).googleWebClientId,
      settings.googleWebClientId,
    );
  });

  test('starts empty but preserves a Sheets URL saved on the device', () async {
    expect(AppSettings.defaults().sourceUrl, isEmpty);
    const savedUrl =
        'https://docs.google.com/spreadsheets/d/LocalSavedSheetId/edit';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'source_url': savedUrl,
    });

    final settings = await SettingsService().load();

    expect(settings.sourceUrl, savedUrl);
  });

  test('parses Sheets URLs and raw spreadsheet IDs', () {
    const id = '1TestSpreadsheetId_0123456789';
    expect(
      SheetsService.spreadsheetIdFromUrl(
        'https://docs.google.com/spreadsheets/d/$id/edit?gid=1',
      ),
      id,
    );
    expect(SheetsService.spreadsheetIdFromUrl(id), id);
    expect(
      () => SheetsService.spreadsheetIdFromUrl('not-a-sheet'),
      throwsFormatException,
    );
  });

  test('calendar duplicate keys match created shifts', () {
    final shift = Shift(
      code: 'UP1',
      rowLabel: 'P1 เช้า',
      assignedName: 'ภาคภูมิ',
      start: DateTime(2026, 8, 3, 8),
      end: DateTime(2026, 8, 3, 16),
      sheetTitle: 'สิงหาคม 2569',
      cell: 'D5',
      category: ShiftCategory.own,
    );

    expect(
      CalendarService.matchesExisting(shift, {CalendarService.keyFor(shift)}),
      isTrue,
    );
    expect(
      CalendarService.matchesExisting(shift, {
        CalendarService.legacyKeyFor(shift),
      }),
      isTrue,
    );
  });

  test('Drive archive lookup is scoped to source file and month', () {
    final query = DriveArchiveService.archiveLookupQuery(
      sourceFileId: 'source-sheet-123',
      period: '2026-08',
    );

    expect(query, contains("key='sourceFileId'"));
    expect(query, contains("value='source-sheet-123'"));
    expect(query, contains("value='2026-08'"));
  });
}
