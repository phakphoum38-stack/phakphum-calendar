import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/audit_entry.dart';
import '../models/calendar_busy_period.dart';
import '../models/saved_sheet.dart';
import '../models/shift.dart';
import '../models/shift_alert.dart';
import '../models/tool_definition.dart';
import '../services/calendar_service.dart';
import '../services/drive_archive_service.dart';
import '../services/drive_ownership_service.dart';
import '../services/google_auth_service.dart';
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
  }) : auth = auth ?? GoogleAuthService(),
       _settingsService = settingsService ?? SettingsService(),
       _sheetsService = sheetsService ?? SheetsService(),
       _parser = parser ?? const ShiftParser(),
       _alertService = alertService ?? const ShiftAlertService(),
       _calendarService = calendarService ?? const CalendarService(),
       _archiveService = archiveService ?? const DriveArchiveService(),
       _ownershipService = ownershipService ?? const DriveOwnershipService();

  AppController.demo()
    : auth = GoogleAuthService(),
      _settingsService = SettingsService(),
      _sheetsService = SheetsService(),
      _parser = const ShiftParser(),
      _alertService = const ShiftAlertService(),
      _calendarService = const CalendarService(),
      _archiveService = const DriveArchiveService(),
      _ownershipService = const DriveOwnershipService() {
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

  AppSettings settings = AppSettings.defaults();
  List<Shift> shifts = [];
  List<ShiftAlert> alerts = [];
  List<CalendarBusyPeriod> calendarPeriods = [];
  Map<String, ShiftAlertDecision> alertDecisions = {};
  List<AuditEntry> auditEntries = [];
  List<SavedSheet> savedSheets = [];
  Set<String> existingKeys = {};
  List<String> sheetTitles = [];
  Set<String> pinnedToolIds = {...defaultPinnedToolIds};
  bool initialized = false;
  bool busy = false;
  String? status;
  String? error;
  DateTime? lastRefresh;
  Timer? _autoRefreshTimer;
  String? _observedAccountId;

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
    final legacyName = settings.targetName.trim();
    if (legacyName.isNotEmpty) names.add(legacyName);
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
    final periodChanged =
        next.year != settings.year || next.month != settings.month;
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
      final sourceUrl = currentSourceUrl;
      if (sourceUrl.isEmpty) {
        throw StateError(
          'กรุณาวางลิงก์และเลือกไฟล์ Google Sheets หลักของบัญชีนี้ก่อน',
        );
      }
      final period = _requirePeriod();
      final searchNames = rosterSearchNames;
      if (searchNames.isEmpty) {
        throw const FormatException(
          'บัญชี Google นี้ไม่มีชื่อที่ใช้ค้นหา กรุณาตรวจชื่อโปรไฟล์ Google',
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
        final parsed = _parser.parse(
          snapshots: snapshots,
          targetName: searchNames.first,
          targetAliases: searchNames.skip(1),
          year: period.year,
          month: period.month,
        );
        shifts = _alertService.addOffDutyPeriods(parsed);
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
            'พบเวรของ ${searchNames.first} ${parsed.length} รายการ • '
            'อ่านสีจากไฟล์หลัก $colorCount รายการ • '
            'สร้าง OFF $offCount รายการ • รอตัดสินใจ $pendingAlertCount รายการ';
        await _addAudit(
          'sheet.read',
          'อ่าน ${snapshots.length} แท็บ พบ ${parsed.length} เวร '
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

  void refreshNow() {
    if (!busy && auth.isSignedIn) {
      unawaited(loadRoster());
    }
  }

  Future<void> compareCalendar() async {
    if (shifts.isEmpty) throw StateError('กรุณาอ่านตารางเวรก่อน');
    await _run('เปรียบเทียบ Google Calendar', () async {
      final period = _requirePeriod();
      final client = await auth.clientFor([
        calendar.CalendarApi.calendarEventsReadonlyScope,
      ]);
      try {
        final snapshot = await _calendarService.readCalendar(
          client,
          year: period.year,
          month: period.month,
        );
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
      final sourceUrl = currentSourceUrl;
      if (sourceUrl.isEmpty) {
        throw StateError('ไม่พบไฟล์ชีตหลักของบัญชีที่ล็อกอิน');
      }
      final period = _requirePeriod();
      final calendarClient = await auth.clientFor([
        calendar.CalendarApi.calendarEventsScope,
      ]);
      try {
        final snapshot = await _calendarService.readCalendar(
          calendarClient,
          year: period.year,
          month: period.month,
        );
        existingKeys = snapshot.sourceKeys;
        calendarPeriods = snapshot.busyPeriods;
        _rebuildAlerts();
        if (pendingAlertCount > 0) {
          throw StateError(
            'พบเวรหรือช่วง OFF ชนกับ Calendar $pendingAlertCount รายการ '
            'จึงยังไม่บันทึก กรุณาตรวจแจ้งเตือนก่อน',
          );
        }

        if (settings.archiveOriginal) {
          final driveClient = await auth.clientFor([drive.DriveApi.driveScope]);
          try {
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
          } finally {
            driveClient.close();
          }
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
    shifts[index] = shifts[index].copyWith(
      category: category,
      excluded: excluded,
    );
    _rebuildAlerts();
    notifyListeners();
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
      lastRefresh = null;
    }
    notifyListeners();
  }

  ({int year, int month}) _requirePeriod() {
    final year = settings.year;
    final month = settings.month;
    if (year == null || month == null) {
      throw StateError('กรุณาเลือกเดือนและปี ค.ศ. ก่อนอ่านตารางเวร');
    }
    return (year: year, month: month);
  }

  void _scheduleAutoRefresh() {
    _autoRefreshTimer?.cancel();
    if (!settings.autoRefresh || shifts.isEmpty || !auth.isSignedIn) return;
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: settings.refreshSeconds.clamp(1, 10)),
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
