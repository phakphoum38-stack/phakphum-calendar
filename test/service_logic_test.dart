import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:phakphum_calendar/models/app_settings.dart';
import 'package:phakphum_calendar/models/saved_sheet.dart';
import 'package:phakphum_calendar/models/roster_period.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/models/shift_alert.dart';
import 'package:phakphum_calendar/models/tool_definition.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';
import 'package:phakphum_calendar/services/drive_archive_service.dart';
import 'package:phakphum_calendar/services/drive_ownership_service.dart';
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
        drive.DriveApi.driveMetadataReadonlyScope,
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

  test('persists saved Sheets separately by opaque account ID', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = SettingsService();
    final savedAt = DateTime(2026, 7, 21, 10, 30);
    final records = <SavedSheet>[
      SavedSheet(
        ownerAccountId: 'account-a',
        spreadsheetId: 'SpreadsheetId_0123456789',
        spreadsheetTitle: 'Roster',
        sheetId: 123,
        sheetTitle: 'August',
        url:
            'https://docs.google.com/spreadsheets/d/SpreadsheetId_0123456789/edit#gid=123',
        savedAt: savedAt,
      ),
      SavedSheet(
        ownerAccountId: 'account-b',
        spreadsheetId: 'AnotherSpreadsheetId_1234',
        spreadsheetTitle: 'Team roster',
        url:
            'https://docs.google.com/spreadsheets/d/AnotherSpreadsheetId_1234/edit',
        savedAt: savedAt.subtract(const Duration(minutes: 1)),
      ),
    ];

    await service.saveSavedSheets(records);
    final loaded = await service.loadSavedSheets();

    expect(loaded, hasLength(2));
    expect(loaded.first.ownerAccountId, 'account-a');
    expect(loaded.first.sheetTitle, 'August');
    expect(loaded.last.ownerAccountId, 'account-b');
  });

  test('persists conflict decisions only in local preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = SettingsService();

    await service.saveAlertDecision(
      'anonymous-alert-id',
      ShiftAlertDecision.acknowledged,
    );

    expect(await service.loadAlertDecisions(), <String, ShiftAlertDecision>{
      'anonymous-alert-id': ShiftAlertDecision.acknowledged,
    });
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

  test('starts Sheet, name, month and year fields empty', () {
    final settings = AppSettings.defaults();

    expect(settings.month, isNull);
    expect(settings.year, isNull);
    expect(settings.targetName, isEmpty);
    expect(settings.effectivePeriods, isEmpty);
  });

  test('supports an unlimited, sorted and de-duplicated period selection', () {
    final settings = AppSettings.defaults().copyWith(
      periods: const [
        RosterPeriod(year: 2027, month: 1),
        RosterPeriod(year: 2026, month: 12),
        RosterPeriod(year: 2027, month: 1),
      ],
    );

    expect(settings.effectivePeriods.map((period) => period.key), [
      '2026-12',
      '2027-01',
    ]);
  });

  test('persists Auto refresh values from 1 through 60 seconds', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final service = SettingsService();

    await service.save(
      AppSettings.defaults().copyWith(autoRefresh: true, refreshSeconds: 60),
    );

    final settings = await service.load();
    expect(settings.autoRefresh, isTrue);
    expect(settings.refreshSeconds, 60);
  });

  test('removes old global Sheet, name, month and year values', () async {
    const savedUrl =
        'https://docs.google.com/spreadsheets/d/LocalSavedSheetId/edit';
    SharedPreferences.setMockInitialValues(<String, Object>{
      'source_url': savedUrl,
      'target_name': 'Old Name',
      'target_year': 2026,
      'target_month': 8,
    });

    final settings = await SettingsService().load();
    final prefs = await SharedPreferences.getInstance();

    expect(settings.targetName, isEmpty);
    expect(settings.year, isNull);
    expect(settings.month, isNull);
    expect(prefs.containsKey('source_url'), isFalse);
    expect(prefs.containsKey('target_name'), isFalse);
    expect(prefs.containsKey('target_year'), isFalse);
    expect(prefs.containsKey('target_month'), isFalse);
  });

  test('accepts only a Google Sheet owned by the signed-in account', () {
    final owned = drive.File(
      mimeType: DriveOwnershipService.googleSheetMimeType,
      ownedByMe: true,
      trashed: false,
    );
    expect(
      () => DriveOwnershipService.validateOwnedSpreadsheet(owned),
      returnsNormally,
    );

    expect(
      () => DriveOwnershipService.validateOwnedSpreadsheet(
        drive.File(
          mimeType: DriveOwnershipService.googleSheetMimeType,
          ownedByMe: false,
        ),
      ),
      throwsStateError,
    );
    expect(
      () => DriveOwnershipService.validateOwnedSpreadsheet(
        drive.File(mimeType: 'application/pdf', ownedByMe: true),
      ),
      throwsStateError,
    );
  });

  test('builds recent Sheet history from owned Drive metadata only', () {
    expect(
      DriveOwnershipService.recentOwnedSheetsQuery,
      allOf(
        contains("mimeType = '${DriveOwnershipService.googleSheetMimeType}'"),
        contains('trashed = false'),
        contains("'me' in owners"),
      ),
    );

    final createdAt = DateTime.utc(2025, 1, 2, 8);
    final modifiedAt = DateTime.utc(2026, 7, 21, 8, 30);
    final recent = DriveOwnershipService.recentOwnedSheetsFromFiles([
      drive.File(
        id: 'owned-sheet-id',
        name: 'ตารางเวรล่าสุด',
        mimeType: DriveOwnershipService.googleSheetMimeType,
        ownedByMe: true,
        trashed: false,
        createdTime: createdAt,
        modifiedByMeTime: modifiedAt,
      ),
      drive.File(
        id: 'shared-sheet-id',
        name: 'ไฟล์ของคนอื่น',
        mimeType: DriveOwnershipService.googleSheetMimeType,
        ownedByMe: false,
      ),
      drive.File(
        id: 'trashed-sheet-id',
        name: 'ไฟล์ในถังขยะ',
        mimeType: DriveOwnershipService.googleSheetMimeType,
        ownedByMe: true,
        trashed: true,
      ),
    ]);

    expect(recent, hasLength(1));
    expect(recent.single.id, 'owned-sheet-id');
    expect(recent.single.modifiedAt, modifiedAt);
    expect(recent.single.createdAt, createdAt);
    expect(
      recent.single.url,
      'https://docs.google.com/spreadsheets/d/owned-sheet-id/edit',
    );
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
      SheetsService.sheetIdFromUrl(
        'https://docs.google.com/spreadsheets/d/$id/edit#gid=456',
      ),
      456,
    );
    expect(SheetsService.sheetUrl(id, 456), endsWith('/edit#gid=456'));
    expect(
      () => SheetsService.spreadsheetIdFromUrl('not-a-sheet'),
      throwsFormatException,
    );
  });

  test('calendar duplicate keys match created shifts', () {
    final shift = Shift(
      code: 'UP1',
      rowLabel: 'P1 เช้า',
      assignedName: 'ผู้ใช้งานทดสอบ',
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
    expect(shift.displayName, 'P1 เช้า (UP1)');
    expect(CalendarService.summaryFor(shift), 'P1 เช้า (UP1)');
    expect(
      CalendarService.matchesExisting(shift, {
        CalendarService.displayLegacyKeyFor(shift),
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
