import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/audit_entry.dart';
import '../models/calendar_busy_period.dart';
import '../models/roster_period.dart';
import '../models/saved_sheet.dart';
import '../models/shift.dart';
import '../models/shift_alert.dart';
import '../models/tool_definition.dart';
import '../services/calendar_service.dart';
import '../services/calendar_color_service.dart';
import '../services/drive_archive_service.dart';
import '../services/drive_ownership_service.dart';
import '../services/google_auth_service.dart';
import '../services/google_api_client.dart';
import '../services/local_roster_file_service.dart';
import '../services/settings_service.dart';
import '../services/sheets_service.dart';
import '../services/shift_alert_service.dart';
import '../services/shift_parser.dart';

class AppController extends ChangeNotifier {
  AppController({
    GoogleAuthService? auth,
    SettingsService? settingsService,
    SheetsService? sheetsService,
    ShiftParser? parser,
    ShiftAlertService? alertService,
    CalendarService? calendarService,
    DriveArchiveService? archiveService,
    DriveOwnershipService? ownershipService,
    LocalRosterFileService? localFileService,
  }) : auth = auth ?? GoogleAuthService(),
       _settingsService = settingsService ?? SettingsService(),
       _sheetsService = sheetsService ?? SheetsService(),
       _parser = parser ?? const ShiftParser(),
       _alertService = alertService ?? const ShiftAlertService(),
       _calendarService = calendarService ?? const CalendarService(),
       _archiveService = archiveService ?? const DriveArchiveService(),
       _ownershipService = ownershipService ?? const DriveOwnershipService(),
       _localFileService = localFileService ?? const LocalRosterFileService();

  AppController.demo()
    : auth = GoogleAuthService(),
      _settingsService = SettingsService(),
      _sheetsService = SheetsService(),
      _parser = const ShiftParser(),
      _alertService = const ShiftAlertService(),
      _calendarService = const CalendarService(),
      _archiveService = const DriveArchiveService(),
      _ownershipService = const DriveOwnershipService(),
      _localFileService = const LocalRosterFileService() {
    initialized = true;
    settings = AppSettings.defaults();
    final sourceShifts = [
      Shift(
        code: 'UP1',
        rowLabel: 'P1 เช้า',
        assignedName: 'ผู้ใช้งานตัวอย่าง',
        start: DateTime(2026, 8, 3, 8),
        end: DateTime(2026, 8, 3, 16),
        sheetTitle: 'ตัวอย่าง',
        cell: 'D5',
        category: ShiftCategory.own,
      ),
      Shift(
        code: 'UG',
        rowLabel: 'GEN',
        assignedName: 'ผู้ใช้งานตัวอย่าง',
        start: DateTime(2026, 8, 8, 7, 30),
        end: DateTime(2026, 8, 8, 12),
        sheetTitle: 'ตัวอย่าง',
        cell: 'I40',
        category: ShiftCategory.clinic,
      ),
      Shift(
        code: 'NP2',
        rowLabel: 'P2 ดึก',
        assignedName: 'ผู้ใช้งานตัวอย่าง',
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 10, 8),
        sheetTitle: 'ตัวอย่าง',
        cell: 'K7',
        category: ShiftCategory.own,
      ),
      Shift(
        code: 'UP3',
        rowLabel: 'P3 เช้า',
        assignedName: 'ผู้ใช้งานตัวอย่าง',
        start: DateTime(2026, 8, 10, 8),
        end: DateTime(2026, 8, 10, 16),
        sheetTitle: 'ตัวอย่าง',
        cell: 'K9',
        category: ShiftCategory.own,
      ),
    ];
    shifts = _alertService.addOffDutyPeriods(sourceShifts);
    _rebuildAlerts();
  }

  final GoogleAuthService auth;
  final SettingsService _settingsService;
  final SheetsService _sheetsService;
  final ShiftParser _parser;
  final ShiftAlertService _alertService;
  final CalendarService _calendarService;
  final DriveArchiveService _archiveService;
  final DriveOwnershipService _ownershipService;
  final LocalRosterFileService _localFileService;

  AppSettings settings = AppSettings.defaults();
  List<Shift> shifts = [];
  List<ShiftAlert> alerts = [];
  List<CalendarBusyPeriod> calendarPeriods = [];
  Map<String, ShiftAlertDecision> alertDecisions = {};
  List<AuditEntry> auditEntries = [];
  List<SavedSheet> savedSheets = [];
  List<RecentOwnedSheet> recentOwnedSheets = [];
  Set<String> existingKeys = {};
  List<String> sheetTitles = [];
  Set<String> pinnedToolIds = {...defaultPinnedToolIds};
  bool initialized = false;
  bool busy = false;
  bool recentSheetHistoryLoaded = false;
  String? status;
  String? error;
  DateTime? lastRefresh;
  Timer? _autoRefreshTimer;
  String? _observedAccountId;
  String? localSourceLabel;
  final Map<String, _ShiftOverride> _shiftOverrides = {};

  int get includedCount => shifts.where((shift) => !shift.excluded).length;
  int get existingCount => shifts
      .where((shift) => CalendarService.matchesExisting(shift, existingKeys))
      .length;
  int get newCount => shifts
      .where(
        (shift) =>
            !shift.excluded &&
            !CalendarService.matchesExisting(shift, existingKeys),
      )
      .length;
  int get pendingAlertCount => alerts.where((alert) => alert.isPending).length;
  int get conflictAlertCount =>
      alerts.where((alert) => alert.isConflict).length;

  List<String> get rosterSearchNames {
    final names = <String>{};
    final enteredName = settings.targetName.trim();
    if (enteredName.isNotEmpty) names.add(enteredName);
    final displayName = auth.account?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) {
      names.add(displayName);
      names.addAll(
        displayName
            .split(RegExp(r'\s+'))
            .map((part) => part.trim())
            .where((part) => part.length >= 2),
      );
    }
    return names.toList(growable: false);
  }

  Future<void> initialize() async {
    if (initialized) return;
    try {
      settings = await _settingsService.load();
    } catch (caught) {
      error = 'โหลดการตั้งค่าไม่สำเร็จ: $caught';
    }
    try {
      auditEntries = await _settingsService.loadAudit();
    } catch (caught) {
      error ??= 'โหลดบันทึกไม่สำเร็จ: $caught';
    }
    try {
      savedSheets = await _settingsService.loadSavedSheets();
    } catch (caught) {
      error ??= 'โหลดรายการชีตที่บันทึกไม่สำเร็จ: $caught';
    }
    try {
      pinnedToolIds = await _settingsService.loadPinnedToolIds();
    } catch (caught) {
      error ??= 'โหลดแถบเครื่องมือไม่สำเร็จ: $caught';
    }
    try {
      alertDecisions = await _settingsService.loadAlertDecisions();
    } catch (caught) {
      error ??= 'โหลดการตัดสินใจแจ้งเตือนไม่สำเร็จ: $caught';
    }
    auth.addListener(_onAuthChanged);
    await auth.initialize(webClientId: settings.googleWebClientId);
    initialized = true;
    notifyListeners();
  }

  Future<void> signIn() => auth.signIn();

  Future<void> authorizeReadAccess() async {
    await _run('ขอสิทธิ์อ่าน Google Sheets, Drive และ Calendar', () async {
      await auth.requestReadAccess();
      status = 'อนุญาตสิทธิ์อ่าน Google Sheets, Drive และ Calendar สำเร็จ';
      await _addAudit('auth.read', status!, true);
    });
  }

  Future<void> signOut() async {
    await auth.signOut();
    _autoRefreshTimer?.cancel();
    shifts = [];
    alerts = [];
    calendarPeriods = [];
    existingKeys = {};
    sheetTitles = [];
    recentOwnedSheets = [];
    localSourceLabel = null;
    _shiftOverrides.clear();
    recentSheetHistoryLoaded = false;
    lastRefresh = null;
    status = 'ออกจากระบบ Google แล้ว';
    notifyListeners();
  }

  Future<void> configureGoogleWebClientId(String value) async {
    final clientId = value.trim();
    if (!GoogleAuthService.isValidWebClientId(clientId)) {
      throw const FormatException(
        'รูปแบบ Google Web OAuth Client ID ไม่ถูกต้อง',
      );
    }
    settings = settings.copyWith(googleWebClientId: clientId);
    await _settingsService.save(settings);
    await auth.configureWebClientId(clientId);
    status = 'ตั้งค่า Google OAuth สำหรับ Web สำเร็จ';
    await _addAudit('auth.configure', status!, true);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings next) async {
    final periodChanged = !listEquals(
      next.effectivePeriods,
      settings.effectivePeriods,
    );
    if (periodChanged) {
      calendarPeriods = [];
      existingKeys = {};
    }
    settings = next;
    await _settingsService.save(next);
    if (periodChanged) _rebuildAlerts();
    _scheduleAutoRefresh();
    notifyListeners();
  }

  Iterable<ToolDefinition> get pinnedTools =>
      toolCatalog.where((tool) => pinnedToolIds.contains(tool.id));

  List<SavedSheet> get savedSheetsForCurrentAccount {
    final accountId = auth.account?.id;
    if (accountId == null) return const [];
    return savedSheets
        .where((sheet) => sheet.ownerAccountId == accountId)
        .toList()
      ..sort((left, right) => right.savedAt.compareTo(left.savedAt));
  }

  SavedSheet? get currentSourceSheet =>
      savedSheetsForCurrentAccount.firstOrNull;

  String get currentSourceUrl => currentSourceSheet?.url ?? '';

  bool get hasSelectedSourceSheet => currentSourceSheet != null;
  bool get hasRosterSource =>
      currentSourceSheet != null || localSourceLabel != null;

  String get selectedSourceSheetTitle =>
      localSourceLabel ??
      currentSourceSheet?.displayTitle ??
      'ยังไม่ได้เลือกแหล่งข้อมูลเวร';

  bool isToolPinned(String id) => pinnedToolIds.contains(id);

  Future<void> toggleToolPinned(ToolDefinition tool) async {
    if (pinnedToolIds.contains(tool.id)) {
      pinnedToolIds = {...pinnedToolIds}..remove(tool.id);
      status = 'นำ ${tool.name} ออกจากแถบแล้ว';
    } else {
      pinnedToolIds = {...pinnedToolIds, tool.id};
      status = 'ติดตั้ง ${tool.name} ในแถบแล้ว';
    }
    await _settingsService.savePinnedToolIds(pinnedToolIds);
    notifyListeners();
  }

  Future<void> openTool(ToolDefinition tool) async {
    final opened = await launchUrl(
      tool.uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened) throw StateError('ไม่สามารถเปิด ${tool.name} ได้');
    status = 'เปิด ${tool.name} แล้ว';
    notifyListeners();
  }

  Future<void> saveCurrentSheet() async {
    final sourceUrl = currentSourceUrl;
    if (sourceUrl.isEmpty) {
      throw StateError('กรุณาเลือกไฟล์ Google Sheets หลักในหน้าแรกก่อน');
    }
    await selectSourceForCurrentAccount(sourceUrl);
  }

  Future<void> findAvailableSourceSheets({
    OwnedSheetOrder order = OwnedSheetOrder.recentlyModified,
  }) async {
    if (!auth.isSignedIn) {
      throw StateError('กรุณาเข้าสู่ระบบ Google ก่อนเลือกไฟล์');
    }

    await _run('กำลังค้นหา Google Sheets จาก Google Drive', () async {
      final client = await auth.clientFor([
        drive.DriveApi.driveMetadataReadonlyScope,
      ]);
      try {
        recentOwnedSheets = await _ownershipService.listOwnedSpreadsheets(
          client,
          limit: 20,
          order: order,
        );
        recentSheetHistoryLoaded = true;
        status = recentOwnedSheets.isEmpty
            ? 'ไม่พบ Google Sheets ที่บัญชีนี้เป็นเจ้าของ'
            : 'พบ Google Sheets ${recentOwnedSheets.length} ไฟล์';
        await _addAudit(
          'drive.sheet_picker.read',
          'อ่านรายการ Google Sheets แบบอ่านอย่างเดียว พบ '
              '${recentOwnedSheets.length} ไฟล์; ไม่บันทึกชื่อไฟล์ใน Audit log',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  Future<void> findRecentSourceSheets() => findAvailableSourceSheets();

  Future<void> selectRecentSourceSheet(RecentOwnedSheet sheet) async {
    await selectRecentSourceSheets([sheet]);
  }

  Future<void> selectRecentSourceSheets(
    List<RecentOwnedSheet> selectedSheets,
  ) async {
    final account = auth.account;
    if (account == null) throw StateError('กรุณาล็อกอิน Google ก่อน');

    final uniqueSheets = <String, RecentOwnedSheet>{
      for (final sheet in selectedSheets) sheet.id: sheet,
    }.values.toList(growable: false);

    if (uniqueSheets.isEmpty) return;

    await _run('ตรวจและเพิ่ม Google Sheets ที่เลือก', () async {
      final client = await auth.clientFor([
        sheets.SheetsApi.spreadsheetsReadonlyScope,
        drive.DriveApi.driveMetadataReadonlyScope,
      ]);

      try {
        var addedCount = 0;

        // บันทึกย้อนลำดับ เพื่อให้ไฟล์แรกที่ผู้ใช้เลือกเป็นไฟล์หลักล่าสุด
        // และยังเก็บไฟล์อื่นทั้งหมดไว้ในรายการชีตที่บันทึก
        for (final selected in uniqueSheets.reversed) {
          await _ownershipService.requireOwnedSpreadsheet(client, selected.id);
          final reference = await _sheetsService.describeSpreadsheet(
            client,
            selected.url,
          );
          await _saveSheetReference(account.id, reference);
          addedCount++;
        }

        status = addedCount == 1
            ? 'เพิ่ม Google Sheets 1 ไฟล์แล้ว'
            : 'เพิ่ม Google Sheets $addedCount ไฟล์แล้ว';
        await _addAudit(
          'sheet.source.add_many',
          'ตรวจสิทธิ์และบันทึก Google Sheets $addedCount ไฟล์ไว้เฉพาะในเครื่อง',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  Future<void> selectSourceForCurrentAccount(String sourceUrl) async {
    final account = auth.account;
    if (account == null) throw StateError('กรุณาล็อกอิน Google ก่อน');
    final normalizedUrl = sourceUrl.trim();
    final spreadsheetId = SheetsService.spreadsheetIdFromUrl(normalizedUrl);
    await _run('ตรวจและเลือกไฟล์ชีตหลักของบัญชีนี้', () async {
      final client = await auth.clientFor([
        sheets.SheetsApi.spreadsheetsReadonlyScope,
        drive.DriveApi.driveMetadataReadonlyScope,
      ]);
      try {
        await _ownershipService.requireOwnedSpreadsheet(client, spreadsheetId);
        final reference = await _sheetsService.describeSpreadsheet(
          client,
          normalizedUrl,
        );
        final saved = await _saveSheetReference(account.id, reference);
        localSourceLabel = null;
        status = 'เลือก “${saved.displayTitle}” เป็นไฟล์หลักของบัญชีนี้แล้ว';
        await _addAudit(
          'sheet.source.select',
          'ตรวจว่าเป็นไฟล์ของบัญชีปัจจุบันและบันทึก “${saved.displayTitle}” '
              'ไว้เฉพาะในเครื่อง',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  Future<void> activateSavedSheet(SavedSheet sheet) async {
    _requireSheetOwner(sheet);
    await selectSourceForCurrentAccount(sheet.url);
  }

  Future<void> openSavedSheet(SavedSheet sheet) async {
    _requireSheetOwner(sheet);
    await _run('เปิดชีตที่บันทึก', () async {
      final opened = await launchUrl(
        Uri.parse(sheet.url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened) throw StateError('ไม่สามารถเปิดลิงก์ Google Sheets ได้');
      status = 'เปิด “${sheet.displayTitle}” แล้ว';
      await _addAudit(
        'sheet.reference.open',
        'เปิดชีตที่บันทึก “${sheet.displayTitle}”',
        true,
      );
    });
  }

  Future<void> deleteSavedSheet(SavedSheet sheet) async {
    _requireSheetOwner(sheet);
    await _run('ลบชีตออกจากรายการบันทึก', () async {
      final wasCurrent = currentSourceSheet?.key == sheet.key;
      savedSheets.removeWhere((item) => item.key == sheet.key);
      await _settingsService.saveSavedSheets(savedSheets);
      if (wasCurrent) {
        shifts = [];
        alerts = [];
        calendarPeriods = [];
        existingKeys = {};
        sheetTitles = [];
        _autoRefreshTimer?.cancel();
      }
      status = 'ลบ “${sheet.displayTitle}” ออกจากรายการแล้ว';
      await _addAudit(
        'sheet.reference.delete',
        'ลบ “${sheet.displayTitle}” ออกจากรายการในเครื่อง; ไม่ได้ลบไฟล์ Google Sheets',
        true,
      );
    });
  }

  Future<void> loadRoster({bool background = false}) async {
    await _run('อ่านตารางเวร', () async {
      final sourceUrl = localSourceLabel == null ? currentSourceUrl : '';
      if (sourceUrl.isEmpty) {
        throw StateError(
          'กรุณาวางลิงก์และเลือกไฟล์ Google Sheets หลักของบัญชีนี้ก่อน',
        );
      }
      final periods = _requirePeriods();
      final searchNames = rosterSearchNames;
      if (searchNames.isEmpty) {
        throw const FormatException(
          'กรุณากรอกชื่อที่ต้องค้นหา หรือตรวจชื่อโปรไฟล์ Google',
        );
      }
      final client = await auth.clientFor([
        sheets.SheetsApi.spreadsheetsReadonlyScope,
        drive.DriveApi.driveMetadataReadonlyScope,
      ], promptIfNecessary: !background);
      try {
        final spreadsheetId = SheetsService.spreadsheetIdFromUrl(sourceUrl);
        await _ownershipService.requireOwnedSpreadsheet(client, spreadsheetId);
        final snapshots = await _sheetsService.readAll(client, sourceUrl);
        final parsedByKey = <String, Shift>{};
        for (final period in periods) {
          final periodShifts = _parser.parse(
            snapshots: snapshots,
            targetName: searchNames.first,
            targetAliases: searchNames.skip(1),
            year: period.year,
            month: period.month,
          );
          for (final shift in periodShifts) {
            parsedByKey[shift.sourceKey] = _applyShiftOverride(shift);
          }
        }
        final parsed = parsedByKey.values.toList()
          ..sort((left, right) => left.start.compareTo(right.start));
        shifts = _alertService.addOffDutyPeriods(parsed);
        localSourceLabel = null;
        sheetTitles = snapshots.map((sheet) => sheet.title).toList();
        existingKeys = {};
        calendarPeriods = [];
        _rebuildAlerts(applyDecisions: true);
        lastRefresh = DateTime.now();
        final offCount = shifts.where((shift) => shift.isOffDuty).length;
        final colorCount = parsed
            .where((shift) => shift.sourceColorValue != null)
            .length;
        status =
            'พบเวรของ ${searchNames.first} ${parsed.length} รายการ '
            'จาก ${periods.length} เดือน • '
            'อ่านสีจากไฟล์หลัก $colorCount รายการ • '
            'สร้าง OFF $offCount รายการ • รอตัดสินใจ $pendingAlertCount รายการ';
        await _addAudit(
          'sheet.read',
          'อ่าน ${snapshots.length} แท็บ ${periods.length} เดือน '
              'พบ ${parsed.length} เวร '
              'อ่านสีจากไฟล์หลัก $colorCount รายการ และสร้าง OFF '
              '$offCount รายการ; ไม่มีการแก้ไขชีต',
          true,
        );
      } finally {
        client.close();
      }
    });
    _scheduleAutoRefresh();
  }

  Future<void> importLocalRosterFile() async {
    final periods = _requirePeriods();
    final searchNames = rosterSearchNames;
    if (searchNames.isEmpty) {
      throw const FormatException(
        'กรุณากรอกชื่อที่ต้องค้นหา หรือล็อกอินเพื่อใช้ชื่อโปรไฟล์ Google',
      );
    }
    await _run('เลือกและอ่านไฟล์ตารางเวรในเครื่อง', () async {
      final document = await _localFileService.pickAndRead();
      if (document == null) {
        status = 'ยกเลิกการเลือกไฟล์';
        return;
      }
      final parsedByKey = <String, Shift>{};
      for (final period in periods) {
        final periodShifts = _parser.parse(
          snapshots: document.snapshots,
          targetName: searchNames.first,
          targetAliases: searchNames.skip(1),
          year: period.year,
          month: period.month,
        );
        for (final shift in periodShifts) {
          parsedByKey[shift.sourceKey] = _applyShiftOverride(shift);
        }
      }
      final parsed = parsedByKey.values.toList()
        ..sort((left, right) => left.start.compareTo(right.start));
      shifts = _alertService.addOffDutyPeriods(parsed);
      sheetTitles = document.snapshots.map((sheet) => sheet.title).toList();
      localSourceLabel = 'ไฟล์ .${document.extension} ในเครื่อง';
      existingKeys = {};
      calendarPeriods = [];
      _autoRefreshTimer?.cancel();
      _rebuildAlerts(applyDecisions: true);
      lastRefresh = DateTime.now();
      status =
          'อ่านไฟล์ .${document.extension} ${document.snapshots.length} แท็บ '
          'พบ ${parsed.length} เวร; ไฟล์ไม่ถูกอัปโหลด';
      await _addAudit(
        'local_file.read',
        'อ่านไฟล์ .${document.extension} ในหน่วยความจำ '
            '${document.snapshots.length} แท็บ พบ ${parsed.length} เวร; '
            'ไม่บันทึกชื่อไฟล์หรือเนื้อหาใน Audit log',
        true,
      );
    });
  }

  void refreshNow() {
    if (!busy && auth.isSignedIn) {
      unawaited(loadRoster());
    }
  }

  Future<void> compareCalendar() async {
    if (shifts.isEmpty) throw StateError('กรุณาอ่านตารางเวรก่อน');
    await _run('เปรียบเทียบ Google Calendar', () async {
      final periods = _requirePeriods();
      final client = await auth.clientFor([
        calendar.CalendarApi.calendarEventsReadonlyScope,
      ]);
      try {
        final snapshot = await _readCalendarPeriods(client, periods);
        existingKeys = snapshot.sourceKeys;
        calendarPeriods = snapshot.busyPeriods;
        _rebuildAlerts();
        status =
            'มีแล้ว $existingCount รายการ • เตรียมเพิ่ม $newCount รายการ • '
            'แจ้งเตือนรอตัดสินใจ $pendingAlertCount รายการ';
        await _addAudit(
          'calendar.compare',
          'ตรวจแบบอ่านอย่างเดียว: มีแล้ว $existingCount, ใหม่ $newCount, '
              'กิจกรรมที่นำมาตรวจชน ${calendarPeriods.length}',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  Future<void> syncCalendar() async {
    if (shifts.isEmpty) throw StateError('กรุณาอ่านตารางเวรก่อน');
    if (pendingAlertCount > 0) {
      throw StateError(
        'มีแจ้งเตือน $pendingAlertCount รายการที่ยังไม่ได้ตัดสินใจ '
        'กรุณาตรวจแจ้งเตือนก่อนบันทึก Calendar',
      );
    }
    await _run('สร้างสำเนาและบันทึกปฏิทิน', () async {
      final sourceUrl = localSourceLabel == null ? currentSourceUrl : '';
      if (sourceUrl.isEmpty && localSourceLabel == null) {
        throw StateError('ไม่พบแหล่งข้อมูลเวรของรอบนี้');
      }
      final periods = _requirePeriods();
      final calendarClient = await auth.clientFor([
        calendar.CalendarApi.calendarEventsScope,
      ]);
      try {
        final snapshot = await _readCalendarPeriods(calendarClient, periods);
        existingKeys = snapshot.sourceKeys;
        calendarPeriods = snapshot.busyPeriods;
        _rebuildAlerts();
        if (pendingAlertCount > 0) {
          throw StateError(
            'พบเวรหรือช่วง OFF ชนกับ Calendar $pendingAlertCount รายการ '
            'จึงยังไม่บันทึก กรุณาตรวจแจ้งเตือนก่อน',
          );
        }

        if (settings.archiveOriginal && sourceUrl.isNotEmpty) {
          final driveClient = await auth.clientFor([drive.DriveApi.driveScope]);
          try {
            for (final period in periods) {
              final archive = await _archiveService.copyMonthlyOriginal(
                driveClient,
                sourceFileId: SheetsService.spreadsheetIdFromUrl(sourceUrl),
                year: period.year,
                month: period.month,
              );
              await _addAudit(
                'drive.copy',
                archive.alreadyExisted
                    ? 'ใช้สำเนาเดิม ${archive.name}; ไม่สร้างซ้ำ'
                    : 'สร้างสำเนาต้นฉบับ ${archive.name}',
                true,
              );
            }
          } finally {
            driveClient.close();
          }
        } else if (settings.archiveOriginal && localSourceLabel != null) {
          await _addAudit(
            'local_file.archive.skip',
            'ไม่อัปโหลดไฟล์ในเครื่องไป Drive อัตโนมัติเพื่อคุ้มครองข้อมูล',
            true,
          );
        }

        final inserted = await _calendarService.insertMissing(
          calendarClient,
          shifts,
          existingKeys,
        );
        status = 'เพิ่ม Google Calendar $inserted รายการสำเร็จ';
        await _addAudit(
          'calendar.write',
          'เพิ่ม $inserted รายการ; ข้ามรายการเดิมและรายการที่ไม่เลือก',
          true,
        );
      } finally {
        calendarClient.close();
      }
    });
  }

  Future<void> createFutureSheet({
    required String templateTitle,
    required String newTitle,
  }) async {
    if (templateTitle.trim().isEmpty || newTitle.trim().isEmpty) {
      throw StateError('กรุณาระบุแท็บต้นแบบและชื่อแท็บใหม่');
    }
    final sourceUrl = currentSourceUrl;
    if (sourceUrl.isEmpty) {
      throw StateError('กรุณาเลือกไฟล์ Google Sheets หลักของบัญชีนี้ก่อน');
    }
    await _run('สร้างชีตเดือนล่วงหน้า', () async {
      final client = await auth.clientFor([
        sheets.SheetsApi.spreadsheetsScope,
        drive.DriveApi.driveMetadataReadonlyScope,
      ]);
      try {
        final spreadsheetId = SheetsService.spreadsheetIdFromUrl(sourceUrl);
        await _ownershipService.requireOwnedSpreadsheet(client, spreadsheetId);
        final created = await _sheetsService.duplicateSheet(
          client,
          sourceUrl: sourceUrl,
          templateTitle: templateTitle.trim(),
          newTitle: newTitle.trim(),
        );
        final createdTitle = created.sheetTitle ?? newTitle.trim();
        if (!sheetTitles.contains(createdTitle)) {
          sheetTitles.add(createdTitle);
        }
        final accountId = auth.account?.id;
        if (accountId != null) {
          await _saveSheetReference(accountId, created);
        }
        status = 'สร้างและบันทึกแท็บ “$createdTitle” สำเร็จ';
        await _addAudit(
          'sheet.create',
          'ทำสำเนาแท็บ “$templateTitle” เป็น “$createdTitle”; ไม่แก้แท็บต้นแบบ',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  void updateShift(int index, {ShiftCategory? category, bool? excluded}) {
    final shift = shifts[index];
    shifts[index] = shift.copyWith(category: category, excluded: excluded);
    if (!shift.generated) {
      _rememberShiftOverride(shifts[index]);
      shifts = _alertService.addOffDutyPeriods(
        shifts.where((item) => !item.generated).toList(),
      );
    }
    _rebuildAlerts();
    notifyListeners();
  }

  void customizeShift(
    int index, {
    required String title,
    required DateTime start,
    required DateTime end,
    required ShiftCategory category,
    required String colorCommand,
  }) {
    final shift = shifts[index];
    if (shift.generated) {
      throw StateError('รายการ OFF อัตโนมัติปรับจากเวรดึกต้นทางเท่านั้น');
    }
    if (!end.isAfter(start)) {
      throw const FormatException('เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม');
    }
    final color = CalendarColorService.parseCommand(colorCommand);
    final updated = shift.copyWith(
      customTitle: title.trim().isEmpty ? shift.displayName : title.trim(),
      start: start,
      end: end,
      category: category,
      calendarColorId: color?.id,
      clearCalendarColor: color == null,
    );
    shifts[index] = updated;
    _rememberShiftOverride(updated);
    shifts = _alertService.addOffDutyPeriods(
      shifts.where((item) => !item.generated).toList(),
    );
    calendarPeriods = [];
    existingKeys = {};
    _rebuildAlerts();
    status = 'ปรับชื่อ เวลา ประเภท และสีของรายการแล้ว';
    notifyListeners();
  }

  Future<void> addManualShift({
    required String sourceKind,
    required String title,
    required DateTime start,
    required DateTime end,
    required ShiftCategory category,
    required String colorCommand,
  }) async {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw const FormatException('กรุณากรอกชื่อกิจกรรมที่อ่านจากต้นฉบับ');
    }
    if (!end.isAfter(start)) {
      throw const FormatException('เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม');
    }
    final searchNames = rosterSearchNames;
    if (searchNames.isEmpty) {
      throw const FormatException(
        'กรุณากรอกชื่อที่ต้องค้นหา หรือล็อกอินเพื่อใช้ชื่อโปรไฟล์ Google',
      );
    }
    final color = CalendarColorService.parseCommand(colorCommand);
    final code =
        'MANUAL-${start.year}${start.month.toString().padLeft(2, '0')}'
        '${start.day.toString().padLeft(2, '0')}-'
        '${start.hour.toString().padLeft(2, '0')}'
        '${start.minute.toString().padLeft(2, '0')}-${shifts.length + 1}';
    final shift = Shift(
      code: code,
      rowLabel: normalizedTitle,
      assignedName: searchNames.first,
      start: start,
      end: end,
      sheetTitle: 'ต้นฉบับ: $sourceKind',
      cell: 'ผู้ใช้กำหนด',
      category: category,
      customTitle: normalizedTitle,
      calendarColorId: color?.id,
    );
    shifts = _alertService.addOffDutyPeriods([
      ...shifts.where((item) => !item.generated),
      shift,
    ]);
    localSourceLabel = 'รายการจาก $sourceKind (ผู้ใช้ตรวจแล้ว)';
    existingKeys = {};
    calendarPeriods = [];
    _rebuildAlerts();
    status = 'เพิ่มรายการจาก $sourceKind แล้ว กรุณาตรวจในแท็บตัวอย่าง';
    await _addAudit(
      'manual_source.add',
      'เพิ่มรายการจาก $sourceKind 1 รายการ; '
          'ไม่บันทึกชื่อกิจกรรมหรือข้อมูลต้นฉบับใน Audit log',
      true,
    );
    notifyListeners();
  }

  Future<void> openCalendarConflict(ShiftAlert alert) async {
    final rawUrl = alert.calendarEventUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      throw StateError('กิจกรรมนี้ไม่มีลิงก์สำหรับเปิดจาก Google Calendar');
    }
    final opened = await launchUrl(
      Uri.parse(rawUrl),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!opened) throw StateError('ไม่สามารถเปิดกิจกรรม Google Calendar ได้');
  }

  Future<void> deleteCalendarConflict(ShiftAlert alert) async {
    final eventId = alert.calendarEventId;
    if (eventId == null || eventId.isEmpty) {
      throw StateError('ไม่พบรหัสกิจกรรม Google Calendar ที่ต้องการลบ');
    }
    await _run('ลบกิจกรรมที่เลือกจาก Google Calendar', () async {
      final client = await auth.clientFor([
        calendar.CalendarApi.calendarEventsScope,
      ]);
      try {
        await _calendarService.deleteEvent(client, eventId: eventId);
        calendarPeriods.removeWhere((period) => period.id == eventId);
        alertDecisions.remove(alert.id);
        _rebuildAlerts();
        status = 'ลบกิจกรรมที่เลือกจาก Google Calendar แล้ว';
        await _addAudit(
          'calendar.delete_conflict',
          'ผู้ใช้ยืนยันลบกิจกรรมที่ชน 1 รายการ',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  Future<void> resolveAlert(String alertId, ShiftAlertDecision decision) async {
    ShiftAlert? alert;
    for (final item in alerts) {
      if (item.id == alertId) {
        alert = item;
        break;
      }
    }
    if (alert == null || !alert.requiresDecision) return;
    alertDecisions[alertId] = decision;
    await _settingsService.saveAlertDecision(alertId, decision);
    _applyAlertDecision(alert, decision);
    _rebuildAlerts();
    status = switch (decision) {
      ShiftAlertDecision.acknowledged => 'รับทราบคำเตือนและคงรายการไว้',
      ShiftAlertDecision.accepted => 'ยืนยันรายการที่ชนแล้ว',
      ShiftAlertDecision.cancelled => 'ไม่นำรายการที่ชนเข้าปฏิทิน',
      ShiftAlertDecision.pending => 'ตั้งเป็นรอตัดสินใจ',
    };
    await _addAudit('alert.${decision.name}', '${alert.title}: $status', true);
    notifyListeners();
  }

  void _rebuildAlerts({bool applyDecisions = false}) {
    alerts = _alertService.build(
      shifts: shifts,
      calendarPeriods: calendarPeriods,
      decisions: alertDecisions,
    );
    if (!applyDecisions) return;
    for (final alert in alerts) {
      _applyAlertDecision(alert, alert.decision);
    }
    alerts = _alertService.build(
      shifts: shifts,
      calendarPeriods: calendarPeriods,
      decisions: alertDecisions,
    );
  }

  void _applyAlertDecision(ShiftAlert alert, ShiftAlertDecision decision) {
    if (!alert.requiresDecision) return;
    switch (decision) {
      case ShiftAlertDecision.pending:
      case ShiftAlertDecision.acknowledged:
        return;
      case ShiftAlertDecision.accepted:
        _setExcluded(alert.targetShiftKey, false);
        if (alert.type == ShiftAlertType.offConflict) {
          _setExcluded(alert.offShiftKey, true);
        }
        return;
      case ShiftAlertDecision.cancelled:
        _setExcluded(alert.targetShiftKey, true);
        return;
    }
  }

  void _setExcluded(String? sourceKey, bool excluded) {
    if (sourceKey == null) return;
    final index = shifts.indexWhere((shift) => shift.sourceKey == sourceKey);
    if (index >= 0) shifts[index] = shifts[index].copyWith(excluded: excluded);
  }

  Future<SavedSheet> _saveSheetReference(
    String accountId,
    SheetReference reference,
  ) async {
    final saved = SavedSheet(
      ownerAccountId: accountId,
      spreadsheetId: reference.spreadsheetId,
      spreadsheetTitle: reference.spreadsheetTitle,
      sheetId: reference.sheetId,
      sheetTitle: reference.sheetTitle,
      url: reference.url,
      savedAt: DateTime.now(),
    );
    savedSheets.removeWhere((item) => item.key == saved.key);
    savedSheets.insert(0, saved);
    await _settingsService.saveSavedSheets(savedSheets);
    return saved;
  }

  void _requireSheetOwner(SavedSheet sheet) {
    final accountId = auth.account?.id;
    if (accountId == null) throw StateError('กรุณาล็อกอิน Google ก่อน');
    if (accountId != sheet.ownerAccountId) {
      throw StateError('รายการนี้เป็นของ Google อีกบัญชีหนึ่ง');
    }
  }

  Future<void> _run(String action, Future<void> Function() body) async {
    if (busy) return;
    busy = true;
    status = action;
    error = null;
    notifyListeners();
    try {
      await body();
    } catch (caught) {
      error = caught.toString().replaceFirst('Bad state: ', '');
      await _addAudit('error', '$action: $error', false);
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _addAudit(String action, String message, bool success) async {
    final entry = AuditEntry(
      timestamp: DateTime.now(),
      action: action,
      message: message,
      success: success,
    );
    auditEntries.insert(0, entry);
    await _settingsService.appendAudit(entry);
  }

  void _onAuthChanged() {
    final accountId = auth.account?.id;
    if (_observedAccountId != accountId) {
      _observedAccountId = accountId;
      settings = settings.clearRosterSelection();
      _autoRefreshTimer?.cancel();
      shifts = [];
      alerts = [];
      calendarPeriods = [];
      existingKeys = {};
      sheetTitles = [];
      recentOwnedSheets = [];
      localSourceLabel = null;
      _shiftOverrides.clear();
      recentSheetHistoryLoaded = false;
      lastRefresh = null;
    }
    notifyListeners();
  }

  List<RosterPeriod> _requirePeriods() {
    final periods = settings.effectivePeriods;
    if (periods.isEmpty) {
      throw StateError('กรุณาเลือกและเพิ่มเดือน/ปี ค.ศ. ก่อนอ่านตารางเวร');
    }
    return periods;
  }

  void _rememberShiftOverride(Shift shift) {
    _shiftOverrides[shift.sourceKey] = _ShiftOverride(
      category: shift.category,
      excluded: shift.excluded,
      start: shift.start,
      end: shift.end,
      customTitle: shift.customTitle,
      calendarColorId: shift.calendarColorId,
    );
  }

  Shift _applyShiftOverride(Shift shift) {
    final override = _shiftOverrides[shift.sourceKey];
    if (override == null) return shift;
    return shift.copyWith(
      category: override.category,
      excluded: override.excluded,
      start: override.start,
      end: override.end,
      customTitle: override.customTitle,
      calendarColorId: override.calendarColorId,
      clearCalendarColor: override.calendarColorId == null,
    );
  }

  Future<CalendarReadResult> _readCalendarPeriods(
    GoogleApiClient client,
    List<RosterPeriod> periods,
  ) async {
    final sourceKeys = <String>{};
    final busyByKey = <String, CalendarBusyPeriod>{};
    for (final period in periods) {
      final snapshot = await _calendarService.readCalendar(
        client,
        year: period.year,
        month: period.month,
      );
      sourceKeys.addAll(snapshot.sourceKeys);
      for (final busyPeriod in snapshot.busyPeriods) {
        busyByKey['${busyPeriod.id}|${busyPeriod.start.toIso8601String()}'] =
            busyPeriod;
      }
    }
    return CalendarReadResult(
      sourceKeys: sourceKeys,
      busyPeriods: busyByKey.values.toList()
        ..sort((left, right) => left.start.compareTo(right.start)),
    );
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (!settings.autoRefresh ||
        shifts.isEmpty ||
        !auth.isSignedIn ||
        currentSourceSheet == null ||
        localSourceLabel != null) {
      return;
    }
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: settings.refreshSeconds.clamp(1, 60)),
      (_) {
        if (busy || !auth.isSignedIn) return;
        unawaited(loadRoster(background: true).catchError((_) {}));
      },
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    auth.removeListener(_onAuthChanged);
    auth.dispose();
    super.dispose();
  }
}

class _ShiftOverride {
  const _ShiftOverride({
    required this.category,
    required this.excluded,
    required this.start,
    required this.end,
    required this.customTitle,
    required this.calendarColorId,
  });

  final ShiftCategory category;
  final bool excluded;
  final DateTime start;
  final DateTime end;
  final String? customTitle;
  final String? calendarColorId;
}
