import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;

import '../models/app_settings.dart';
import '../models/audit_entry.dart';
import '../models/calendar_busy_period.dart';
import '../models/shift.dart';
import '../models/shift_alert.dart';
import '../services/calendar_service.dart';
import '../services/drive_archive_service.dart';
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
  }) : auth = auth ?? GoogleAuthService(),
       _settingsService = settingsService ?? SettingsService(),
       _sheetsService = sheetsService ?? SheetsService(),
       _parser = parser ?? const ShiftParser(),
       _alertService = alertService ?? const ShiftAlertService(),
       _calendarService = calendarService ?? const CalendarService(),
       _archiveService = archiveService ?? const DriveArchiveService();

  AppController.demo()
    : auth = GoogleAuthService(),
      _settingsService = SettingsService(),
      _sheetsService = SheetsService(),
      _parser = const ShiftParser(),
      _alertService = const ShiftAlertService(),
      _calendarService = const CalendarService(),
      _archiveService = const DriveArchiveService() {
    initialized = true;
    settings = AppSettings.defaults();
    final sourceShifts = [
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
      Shift(
        code: 'NP2',
        rowLabel: 'P2 ดึก',
        assignedName: 'ภาคภูมิ',
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 10, 8),
        sheetTitle: 'ตัวอย่าง',
        cell: 'K7',
        category: ShiftCategory.own,
      ),
      Shift(
        code: 'UP3',
        rowLabel: 'P3 เช้า',
        assignedName: 'ภาคภูมิ',
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

  AppSettings settings = AppSettings.defaults();
  List<Shift> shifts = [];
  List<ShiftAlert> alerts = [];
  List<CalendarBusyPeriod> calendarPeriods = [];
  Map<String, ShiftAlertDecision> alertDecisions = {};
  List<AuditEntry> auditEntries = [];
  Set<String> existingKeys = {};
  List<String> sheetTitles = [];
  bool initialized = false;
  bool busy = false;
  bool hasPasskey = false;
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
  int get pendingAlertCount => alerts.where((alert) => alert.isPending).length;
  int get conflictAlertCount =>
      alerts.where((alert) => alert.isConflict).length;

  Future<void> initialize() async {
    if (initialized) return;
    settings = await _settingsService.load();
    auditEntries = await _settingsService.loadAudit();
    alertDecisions = await _settingsService.loadAlertDecisions();
    hasPasskey = await _settingsService.hasPasskey();
    auth.addListener(_onAuthChanged);
    await auth.initialize();
    initialized = true;
    notifyListeners();
  }

  Future<void> signIn() => auth.signIn();
  Future<void> signOut() => auth.signOut();

  Future<void> updateSettings(AppSettings next) async {
    if (next.year != settings.year || next.month != settings.month) {
      calendarPeriods = [];
      existingKeys = {};
    }
    settings = next;
    await _settingsService.save(next);
    _scheduleAutoRefresh();
    notifyListeners();
  }

  Future<void> setPasskey(String value) async {
    await _settingsService.setPasskey(value);
    hasPasskey = true;
    await _addAudit('security', 'ตั้งค่าหรือเปลี่ยน passkey สำเร็จ', true);
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
        final parsed = _parser.parse(
          snapshots: snapshots,
          targetName: settings.targetName,
          year: settings.year,
          month: settings.month,
        );
        shifts = _alertService.addOffDutyPeriods(parsed);
        _rebuildAlerts(applyDecisions: true);
        sheetTitles = snapshots.map((sheet) => sheet.title).toList();
        lastRefresh = DateTime.now();
        status =
            'พบ ${parsed.length} เวร และสร้างเวรออฟ '
            '${shifts.length - parsed.length} รายการ; '
            'มีแจ้งเตือนรอตัดสินใจ $pendingAlertCount รายการ';
        await _addAudit(
          'sheet.read',
          'อ่าน ${snapshots.length} แท็บ พบ ${parsed.length} เวร '
              'และเวรออฟ ${shifts.length - parsed.length}; ไม่มีการแก้ไขชีต',
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
        final snapshot = await _calendarService.readCalendar(
          client,
          year: settings.year,
          month: settings.month,
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

  Future<void> syncCalendar(String passkey) async {
    if (shifts.isEmpty) throw StateError('กรุณาอ่านตารางเวรก่อน');
    if (pendingAlertCount > 0) {
      throw StateError(
        'มีแจ้งเตือน $pendingAlertCount รายการที่ยังไม่ได้ตัดสินใจ '
        'กรุณาเปิดแท็บแจ้งเตือนก่อนบันทึก Calendar',
      );
    }
    if (!await _settingsService.verifyPasskey(passkey)) {
      await _addAudit('security', 'ปฏิเสธการเขียน: passkey ไม่ถูกต้อง', false);
      throw StateError('Passkey ไม่ถูกต้อง');
    }
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
    required String passkey,
    required String templateTitle,
    required String newTitle,
  }) async {
    if (!await _settingsService.verifyPasskey(passkey)) {
      await _addAudit(
        'security',
        'ปฏิเสธการสร้างชีต: passkey ไม่ถูกต้อง',
        false,
      );
      throw StateError('Passkey ไม่ถูกต้อง');
    }
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

  Future<void> resolveAlert(String alertId, ShiftAlertDecision decision) async {
    final alert = alerts.cast<ShiftAlert?>().firstWhere(
      (item) => item?.id == alertId,
      orElse: () => null,
    );
    if (alert == null) return;
    alertDecisions[alertId] = decision;
    await _settingsService.saveAlertDecision(alertId, decision);

    if (decision == ShiftAlertDecision.accepted) {
      if (alert.type == ShiftAlertType.offAfterNight) {
        _setExcluded(alert.offShiftKey, true);
      } else {
        _setExcluded(alert.targetShiftKey, false);
        if (alert.type == ShiftAlertType.offConflict) {
          _setExcluded(alert.offShiftKey, true);
        }
      }
    } else if (decision == ShiftAlertDecision.cancelled) {
      _setExcluded(
        alert.type == ShiftAlertType.offAfterNight
            ? alert.offShiftKey
            : alert.targetShiftKey,
        true,
      );
    }

    _rebuildAlerts();
    status = switch (decision) {
      ShiftAlertDecision.acknowledged => 'ยอมรับคำเตือนแล้ว',
      ShiftAlertDecision.accepted => 'ยืนยันรับเวรและบันทึกการตัดสินใจแล้ว',
      ShiftAlertDecision.cancelled => 'ยกเลิกรายการที่ชนแล้ว',
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
      if (alert.decision == ShiftAlertDecision.cancelled) {
        _setExcluded(
          alert.type == ShiftAlertType.offAfterNight
              ? alert.offShiftKey
              : alert.targetShiftKey,
          true,
        );
      } else if (alert.decision == ShiftAlertDecision.accepted) {
        if (alert.type == ShiftAlertType.offAfterNight) {
          _setExcluded(alert.offShiftKey, true);
        } else {
          _setExcluded(alert.targetShiftKey, false);
          if (alert.type == ShiftAlertType.offConflict) {
            _setExcluded(alert.offShiftKey, true);
          }
        }
      }
    }
    alerts = _alertService.build(
      shifts: shifts,
      calendarPeriods: calendarPeriods,
      decisions: alertDecisions,
    );
  }

  void _setExcluded(String? sourceKey, bool excluded) {
    if (sourceKey == null) return;
    final index = shifts.indexWhere((shift) => shift.sourceKey == sourceKey);
    if (index >= 0) shifts[index] = shifts[index].copyWith(excluded: excluded);
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

  void _onAuthChanged() => notifyListeners();

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
