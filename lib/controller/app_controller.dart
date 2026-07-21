import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/audit_entry.dart';
import '../models/shift.dart';
import '../models/tool_definition.dart';
import '../services/calendar_service.dart';
import '../services/drive_archive_service.dart';
import '../services/google_auth_service.dart';
import '../services/settings_service.dart';
import '../services/sheets_service.dart';
import '../services/shift_parser.dart';

class AppController extends ChangeNotifier {
  AppController({
    GoogleAuthService? auth,
    SettingsService? settingsService,
    SheetsService? sheetsService,
    ShiftParser? parser,
    CalendarService? calendarService,
    DriveArchiveService? archiveService,
  }) : auth = auth ?? GoogleAuthService(),
       _settingsService = settingsService ?? SettingsService(),
       _sheetsService = sheetsService ?? SheetsService(),
       _parser = parser ?? const ShiftParser(),
       _calendarService = calendarService ?? const CalendarService(),
       _archiveService = archiveService ?? const DriveArchiveService();

  AppController.demo()
    : auth = GoogleAuthService(),
      _settingsService = SettingsService(),
      _sheetsService = SheetsService(),
      _parser = const ShiftParser(),
      _calendarService = const CalendarService(),
      _archiveService = const DriveArchiveService() {
    initialized = true;
    settings = AppSettings.defaults();
    shifts = [
      Shift(
        code: 'UP1',
        rowLabel: 'P1 เช้า',
        assignedName: 'ภาคภูมิ',
        start: DateTime(2026, 8, 3, 8),
        end: DateTime(2026, 8, 3, 16),
        sheetTitle: 'ตัวอย่าง',
        cell: 'D5',
        category: ShiftCategory.own,
      ),
      Shift(
        code: 'UG',
        rowLabel: 'GEN',
        assignedName: 'ภาคภูมิ',
        start: DateTime(2026, 8, 8, 7, 30),
        end: DateTime(2026, 8, 8, 12),
        sheetTitle: 'ตัวอย่าง',
        cell: 'I40',
        category: ShiftCategory.clinic,
      ),
    ];
  }

  final GoogleAuthService auth;
  final SettingsService _settingsService;
  final SheetsService _sheetsService;
  final ShiftParser _parser;
  final CalendarService _calendarService;
  final DriveArchiveService _archiveService;

  AppSettings settings = AppSettings.defaults();
  List<Shift> shifts = [];
  List<AuditEntry> auditEntries = [];
  Set<String> existingKeys = {};
  List<String> sheetTitles = [];
  Set<String> pinnedToolIds = {...defaultPinnedToolIds};
  bool initialized = false;
  bool busy = false;
  String? status;
  String? error;
  DateTime? lastRefresh;
  Timer? _autoRefreshTimer;

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
      pinnedToolIds = await _settingsService.loadPinnedToolIds();
    } catch (caught) {
      error ??= 'โหลดแถบเครื่องมือไม่สำเร็จ: $caught';
    }
    auth.addListener(_onAuthChanged);
    await auth.initialize(webClientId: settings.googleWebClientId);
    initialized = true;
    notifyListeners();
  }

  Future<void> signIn() => auth.signIn();

  Future<void> authorizeReadAccess() async {
    await _run('ขอสิทธิ์อ่าน Google Sheets และ Calendar', () async {
      await auth.requestReadAccess();
      status = 'อนุญาตสิทธิ์อ่าน Google Sheets และ Calendar สำเร็จ';
      await _addAudit('auth.read', status!, true);
    });
    await loadRoster();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _autoRefreshTimer?.cancel();
    shifts = [];
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
    settings = next;
    await _settingsService.save(next);
    _scheduleAutoRefresh();
    notifyListeners();
  }

  Iterable<ToolDefinition> get pinnedTools =>
      toolCatalog.where((tool) => pinnedToolIds.contains(tool.id));

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

  Future<void> loadRoster({bool background = false}) async {
    await _run('อ่านตารางเวร', () async {
      final client = await auth.clientFor([
        sheets.SheetsApi.spreadsheetsReadonlyScope,
      ], promptIfNecessary: !background);
      try {
        final snapshots = await _sheetsService.readAll(
          client,
          settings.sourceUrl,
        );
        shifts = _parser.parse(
          snapshots: snapshots,
          targetName: settings.targetName,
          year: settings.year,
          month: settings.month,
        );
        sheetTitles = snapshots.map((sheet) => sheet.title).toList();
        existingKeys = {};
        lastRefresh = DateTime.now();
        status = 'พบเวรของ ${settings.targetName} ${shifts.length} รายการ';
        await _addAudit(
          'sheet.read',
          'อ่าน ${snapshots.length} แท็บ พบ ${shifts.length} เวร; ไม่มีการแก้ไขชีต',
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
      final client = await auth.clientFor([
        calendar.CalendarApi.calendarEventsReadonlyScope,
      ]);
      try {
        existingKeys = await _calendarService.existingSourceKeys(
          client,
          year: settings.year,
          month: settings.month,
        );
        status = 'มีแล้ว $existingCount รายการ • เตรียมเพิ่ม $newCount รายการ';
        await _addAudit(
          'calendar.compare',
          'ตรวจแบบอ่านอย่างเดียว: มีแล้ว $existingCount, ใหม่ $newCount',
          true,
        );
      } finally {
        client.close();
      }
    });
  }

  Future<void> syncCalendar() async {
    if (shifts.isEmpty) throw StateError('กรุณาอ่านตารางเวรก่อน');
    await _run('สร้างสำเนาและบันทึกปฏิทิน', () async {
      if (settings.archiveOriginal) {
        final driveClient = await auth.clientFor([drive.DriveApi.driveScope]);
        try {
          final archive = await _archiveService.copyMonthlyOriginal(
            driveClient,
            sourceFileId: SheetsService.spreadsheetIdFromUrl(
              settings.sourceUrl,
            ),
            year: settings.year,
            month: settings.month,
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

      final calendarClient = await auth.clientFor([
        calendar.CalendarApi.calendarEventsScope,
      ]);
      try {
        existingKeys = await _calendarService.existingSourceKeys(
          calendarClient,
          year: settings.year,
          month: settings.month,
        );
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
    await _run('สร้างชีตเดือนล่วงหน้า', () async {
      final client = await auth.clientFor([sheets.SheetsApi.spreadsheetsScope]);
      try {
        final created = await _sheetsService.duplicateSheet(
          client,
          sourceUrl: settings.sourceUrl,
          templateTitle: templateTitle.trim(),
          newTitle: newTitle.trim(),
        );
        if (!sheetTitles.contains(created)) sheetTitles.add(created);
        status = 'สร้างแท็บ “$created” สำเร็จ';
        await _addAudit(
          'sheet.create',
          'ทำสำเนาแท็บ “$templateTitle” เป็น “$created”; ไม่แก้แท็บต้นแบบ',
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
    notifyListeners();
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
    if (!auth.isSignedIn) _autoRefreshTimer?.cancel();
    notifyListeners();
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
