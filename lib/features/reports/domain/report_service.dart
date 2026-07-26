import 'dart:typed_data';

import '../../../core/result/result.dart';
import '../../../domain/entities/schedule.dart';
import 'monthly_report_options.dart';

/// Generates a printable monthly report from a canonical schedule.
abstract interface class MonthlyScheduleReportService {
  Future<Result<Uint8List>> generate(
    Schedule schedule,
    MonthlyReportOptions options,
  );
}

/// Outcome of an explicit platform print or share operation.
enum ReportOutputOutcome { completed, cancelled }

/// Platform boundary for printing and sharing generated PDF bytes.
abstract interface class ReportOutputGateway {
  Future<Result<ReportOutputOutcome>> printPdf(
    Uint8List bytes, {
    required String documentName,
  });

  Future<Result<ReportOutputOutcome>> sharePdf(
    Uint8List bytes, {
    required String fileName,
  });
}
