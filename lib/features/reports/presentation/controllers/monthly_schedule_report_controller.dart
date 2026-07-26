import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../../../core/state/controller_state.dart';
import '../../../../domain/entities/department.dart';
import '../../../../domain/entities/schedule.dart';
import '../../domain/monthly_report_options.dart';
import '../../domain/report_service.dart';

/// Explicit lifecycle states for preview and platform output operations.
enum MonthlyReportStatus {
  idle,
  preparing,
  ready,
  saving,
  printing,
  success,
  failure,
}

/// Owns transient monthly PDF preview and explicit output operations.
class MonthlyScheduleReportController extends ChangeNotifier
    implements ControllerState {
  MonthlyScheduleReportController({
    required this.schedule,
    required this._reportService,
    required this._outputGateway,
    required MonthlyReportOptions initialOptions,
  }) : _options = initialOptions;

  final Schedule schedule;
  final MonthlyScheduleReportService _reportService;
  final ReportOutputGateway _outputGateway;

  MonthlyReportOptions _options;
  MonthlyReportStatus _status = MonthlyReportStatus.idle;
  Uint8List? _pdfBytes;
  String? _message;
  String? _error;

  MonthlyReportOptions get options => _options;
  MonthlyReportStatus get status => _status;
  Uint8List? get pdfBytes => _pdfBytes;
  bool get hasPreview => _pdfBytes != null;

  List<DateTime> get availableMonths {
    final months = schedule.months.map((month) => month.month).toList()..sort();
    return List.unmodifiable(months);
  }

  List<Department> get availableDepartments {
    final departments = <String, Department>{};
    for (final month in schedule.months) {
      for (final day in month.days) {
        for (final assignment in day.assignments) {
          departments[assignment.employee.department.id] =
              assignment.employee.department;
        }
      }
    }
    final values = departments.values.toList()
      ..sort((left, right) {
        final byName = left.name.toLowerCase().compareTo(
          right.name.toLowerCase(),
        );
        return byName == 0 ? left.id.compareTo(right.id) : byName;
      });
    return List.unmodifiable(values);
  }

  @override
  bool get loading =>
      _status == MonthlyReportStatus.preparing ||
      _status == MonthlyReportStatus.saving ||
      _status == MonthlyReportStatus.printing;

  @override
  String? get error => _error;

  @override
  bool get success => _status == MonthlyReportStatus.success;

  @override
  String? get message => _message;

  void selectMonth(DateTime month) {
    _options = _options.copyWith(month: DateTime(month.year, month.month));
    _invalidatePreview();
  }

  void selectDepartment(String? departmentId) {
    _options = departmentId == null
        ? _options.copyWith(clearDepartment: true)
        : _options.copyWith(departmentId: departmentId);
    _invalidatePreview();
  }

  void updateOptions(MonthlyReportOptions options) {
    _options = options;
    _invalidatePreview();
  }

  Future<Result<Uint8List>> generate() async {
    _setBusy(MonthlyReportStatus.preparing);
    final result = await _reportService.generate(schedule, _options);
    switch (result) {
      case Success<Uint8List>(value: final value):
        _pdfBytes = value;
        _status = MonthlyReportStatus.ready;
        _message = 'สร้างตัวอย่างรายงานแล้ว';
        _error = null;
      case Failure<Uint8List>(message: final failureMessage):
        _status = MonthlyReportStatus.failure;
        _message = null;
        _error = failureMessage;
    }
    notifyListeners();
    return result;
  }

  Future<Result<ReportOutputOutcome>> printReport() async {
    final bytesResult = await _requireBytes();
    if (bytesResult case Failure<Uint8List>()) {
      return ValidationFailure(bytesResult.message);
    }
    _setBusy(MonthlyReportStatus.printing);
    final result = await _outputGateway.printPdf(
      (bytesResult as Success<Uint8List>).value,
      documentName: fileName,
    );
    _applyOutputResult(result, successMessage: 'ส่งรายงานไปยังระบบพิมพ์แล้ว');
    return result;
  }

  Future<Result<ReportOutputOutcome>> shareReport() async {
    final bytesResult = await _requireBytes();
    if (bytesResult case Failure<Uint8List>()) {
      return ValidationFailure(bytesResult.message);
    }
    _setBusy(MonthlyReportStatus.saving);
    final result = await _outputGateway.sharePdf(
      (bytesResult as Success<Uint8List>).value,
      fileName: fileName,
    );
    _applyOutputResult(
      result,
      successMessage: 'เปิดการบันทึกหรือแชร์รายงานแล้ว',
    );
    return result;
  }

  String get fileName {
    final year = _options.month.year.toString().padLeft(4, '0');
    final month = _options.month.month.toString().padLeft(2, '0');
    return 'shift_schedule_${year}_$month.pdf';
  }

  Future<Result<Uint8List>> _requireBytes() async {
    final bytes = _pdfBytes;
    return bytes == null ? generate() : Success(bytes);
  }

  void _applyOutputResult(
    Result<ReportOutputOutcome> result, {
    required String successMessage,
  }) {
    switch (result) {
      case Success<ReportOutputOutcome>(value: final outcome):
        if (outcome == ReportOutputOutcome.completed) {
          _status = MonthlyReportStatus.success;
          _message = successMessage;
        } else {
          _status = MonthlyReportStatus.ready;
          _message = 'ยกเลิกการดำเนินการ';
        }
        _error = null;
      case Failure<ReportOutputOutcome>(message: final failureMessage):
        _status = MonthlyReportStatus.failure;
        _message = null;
        _error = failureMessage;
    }
    notifyListeners();
  }

  void _setBusy(MonthlyReportStatus status) {
    _status = status;
    _message = null;
    _error = null;
    notifyListeners();
  }

  void _invalidatePreview() {
    _pdfBytes = null;
    _status = MonthlyReportStatus.idle;
    _message = null;
    _error = null;
    notifyListeners();
  }
}
