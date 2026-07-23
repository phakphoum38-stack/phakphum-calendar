import 'package:flutter/foundation.dart';

import '../../calendar_engine/application/resilient_calendar_sync_executor.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../../relationship_engine/domain/user_shift_change.dart';
import '../domain/workflow_preview.dart';
import 'calendar_sync_coordinator.dart';
import 'workflow_preview_builder.dart';

class ShiftCalendarWorkflowController extends ChangeNotifier {
  ShiftCalendarWorkflowController({
    required this._previewBuilder,
    required this._syncCoordinator,
  });

  final WorkflowPreviewBuilder _previewBuilder;
  final CalendarSyncCoordinator _syncCoordinator;

  WorkflowPreview? _preview;
  bool _isBusy = false;
  String? _message;
  ResilientCalendarSyncResult? _lastResult;

  WorkflowPreview? get preview => _preview;
  bool get isBusy => _isBusy;
  String? get message => _message;
  ResilientCalendarSyncResult? get lastResult => _lastResult;

  void preparePreview({
    required List<UserShiftChange> changes,
    required List<CalendarEventCandidate> existing,
  }) {
    _preview = _previewBuilder.build(changes: changes, existing: existing);
    _message = null;
    notifyListeners();
  }

  Future<void> synchronize({String calendarId = 'primary'}) async {
    final current = _preview;
    if (current == null) {
      _message = 'ยังไม่มีผลการตรวจสอบสำหรับซิงก์';
      notifyListeners();
      return;
    }
    if (!current.simulation.summary.canSynchronize) {
      _message = 'ยังมีรายการที่ถูกบล็อก กรุณาตรวจสอบก่อนซิงก์';
      notifyListeners();
      return;
    }

    _isBusy = true;
    _message = null;
    notifyListeners();

    try {
      _lastResult = await _syncCoordinator.synchronize(
        diff: current.diff,
        timeMin: current.timeMin,
        timeMax: current.timeMax,
        calendarId: calendarId,
      );
      _message = _lastResult!.hasFailures
          ? 'ซิงก์สำเร็จบางส่วน กรุณาตรวจสอบประวัติ'
          : 'ซิงก์ Google Calendar สำเร็จ';
    } catch (_) {
      _message = 'ซิงก์ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตและสิทธิ์ Google';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
