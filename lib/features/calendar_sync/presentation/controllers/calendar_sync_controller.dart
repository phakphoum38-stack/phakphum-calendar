import 'package:flutter/foundation.dart';

import '../../../diff_engine/domain/calendar_event_candidate.dart';
import '../../domain/calendar_sync_progress.dart';
import '../../domain/calendar_sync_run_result.dart';

enum CalendarSyncStatus {
  idle,
  previewing,
  previewReady,
  syncing,
  success,
  failure,
}

typedef CalendarSyncRunOperation = Future<CalendarSyncRunResult> Function({
  required List<CalendarEventCandidate> desiredEvents,
  required DateTime timeMin,
  required DateTime timeMax,
  bool dryRun,
  bool continueOnError,
  CalendarSyncProgressCallback? onProgress,
});

class CalendarSyncController extends ChangeNotifier {
  // ignore: prefer_initializing_formals
  CalendarSyncController({
    required this._syncOperation,
    required List<CalendarEventCandidate> desiredEvents,
    required DateTime timeMin,
    required DateTime timeMax,
    this.continueOnError = false,
  }) : _desiredEvents = List.unmodifiable(desiredEvents),
       _timeMin = timeMin,
       _timeMax = timeMax {
    _validateTimeRange(timeMin, timeMax);
  }

  final CalendarSyncRunOperation _syncOperation;

  List<CalendarEventCandidate> _desiredEvents;
  DateTime _timeMin;
  DateTime _timeMax;

  bool continueOnError;

  CalendarSyncStatus _status = CalendarSyncStatus.idle;
  CalendarSyncProgress? _progress;
  CalendarSyncRunResult? _previewResult;
  CalendarSyncRunResult? _syncResult;
  Object? _error;
  StackTrace? _stackTrace;

  CalendarSyncStatus get status => _status;
  CalendarSyncProgress? get progress => _progress;
  CalendarSyncRunResult? get previewResult => _previewResult;
  CalendarSyncRunResult? get syncResult => _syncResult;
  Object? get error => _error;
  StackTrace? get stackTrace => _stackTrace;

  List<CalendarEventCandidate> get desiredEvents => _desiredEvents;
  DateTime get timeMin => _timeMin;
  DateTime get timeMax => _timeMax;

  bool get isPreviewing {
    return _status == CalendarSyncStatus.previewing;
  }

  bool get isSyncing {
    return _status == CalendarSyncStatus.syncing;
  }

  bool get isBusy {
    return isPreviewing || isSyncing;
  }

  bool get hasError {
    return _status == CalendarSyncStatus.failure && _error != null;
  }

  bool get hasPreview {
    return _previewResult != null;
  }

  bool get hasSyncResult {
    return _syncResult != null;
  }

  double get progressFraction {
    return _progress?.fraction ?? 0;
  }

  int get progressPercent {
    return (progressFraction * 100).round();
  }

  String get progressMessage {
    return _progress?.message ?? '';
  }

  String? get errorMessage {
    return _error?.toString();
  }

  void updateRequest({
    required List<CalendarEventCandidate> desiredEvents,
    required DateTime timeMin,
    required DateTime timeMax,
  }) {
    if (isBusy) {
      throw StateError(
        'Cannot update the calendar sync request while an operation is running.',
      );
    }

    _validateTimeRange(timeMin, timeMax);

    _desiredEvents = List.unmodifiable(desiredEvents);
    _timeMin = timeMin;
    _timeMax = timeMax;

    _status = CalendarSyncStatus.idle;
    _progress = null;
    _previewResult = null;
    _syncResult = null;
    _error = null;
    _stackTrace = null;

    notifyListeners();
  }

  Future<void> preview() async {
    if (isBusy) {
      return;
    }

    _begin(CalendarSyncStatus.previewing);

    try {
      final result = await _run(dryRun: true);

      _previewResult = result;
      _complete(CalendarSyncStatus.previewReady);
    } catch (error, stackTrace) {
      _fail(error, stackTrace);
      rethrow;
    }
  }

  Future<void> sync() async {
    if (isBusy) {
      return;
    }

    _begin(CalendarSyncStatus.syncing);

    try {
      final result = await _run(dryRun: false);

      _syncResult = result;
      _complete(CalendarSyncStatus.success);
    } catch (error, stackTrace) {
      _fail(error, stackTrace);
      rethrow;
    }
  }

  Future<CalendarSyncRunResult> _run({required bool dryRun}) {
    return _syncOperation(
      desiredEvents: _desiredEvents,
      timeMin: _timeMin,
      timeMax: _timeMax,
      dryRun: dryRun,
      continueOnError: continueOnError,
      onProgress: _handleProgress,
    );
  }

  void _handleProgress(CalendarSyncProgress progress) {
    _progress = progress;
    notifyListeners();
  }

  void reset() {
    if (isBusy) {
      return;
    }

    _status = CalendarSyncStatus.idle;
    _progress = null;
    _previewResult = null;
    _syncResult = null;
    _error = null;
    _stackTrace = null;

    notifyListeners();
  }

  void _begin(CalendarSyncStatus status) {
    _status = status;
    _progress = null;
    _error = null;
    _stackTrace = null;

    notifyListeners();
  }

  void _complete(CalendarSyncStatus status) {
    _status = status;
    _error = null;
    _stackTrace = null;

    notifyListeners();
  }

  void _fail(Object error, StackTrace stackTrace) {
    _status = CalendarSyncStatus.failure;
    _error = error;
    _stackTrace = stackTrace;

    notifyListeners();
  }

  void _validateTimeRange(DateTime timeMin, DateTime timeMax) {
    if (!timeMax.isAfter(timeMin)) {
      throw ArgumentError.value(
        timeMax,
        'timeMax',
        'timeMax must be after timeMin.',
      );
    }
  }
}
