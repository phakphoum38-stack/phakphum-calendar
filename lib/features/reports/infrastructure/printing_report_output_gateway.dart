import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../../../core/result/result.dart';
import '../domain/report_service.dart';

/// Uses the maintained Printing plugin for native print and share flows.
class PrintingReportOutputGateway implements ReportOutputGateway {
  const PrintingReportOutputGateway();

  @override
  Future<Result<ReportOutputOutcome>> printPdf(
    Uint8List bytes, {
    required String documentName,
  }) async {
    try {
      final completed = await Printing.layoutPdf(
        name: documentName,
        onLayout: (_) async => bytes,
      );
      return Success(
        completed
            ? ReportOutputOutcome.completed
            : ReportOutputOutcome.cancelled,
      );
    } catch (error, stackTrace) {
      return PersistenceFailure(
        'ไม่สามารถเปิดระบบพิมพ์ได้',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<Result<ReportOutputOutcome>> sharePdf(
    Uint8List bytes, {
    required String fileName,
  }) async {
    try {
      final completed = await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      return Success(
        completed
            ? ReportOutputOutcome.completed
            : ReportOutputOutcome.cancelled,
      );
    } catch (error, stackTrace) {
      return PersistenceFailure(
        'ไม่สามารถบันทึกหรือแชร์ไฟล์ PDF ได้',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
