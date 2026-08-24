import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/result/result.dart';
import '../../../domain/entities/schedule.dart';
import '../application/monthly_schedule_report_mapper.dart';
import '../domain/monthly_report_options.dart';
import '../domain/monthly_schedule_report.dart';
import '../domain/report_labels.dart';
import '../domain/report_service.dart';

/// Supplies Thai-capable fonts to the PDF renderer.
typedef ReportFontLoader = Future<({pw.Font regular, pw.Font bold})> Function();

/// Renders the canonical monthly report model as a printable A4 PDF.
class MonthlySchedulePdfService implements MonthlyScheduleReportService {
  MonthlySchedulePdfService({
    this.mapper = const MonthlyScheduleReportMapper(),
    ReportFontLoader? fontLoader,
    this.labels = const ReportLabels(),
  }) : _fontLoader = fontLoader ?? _loadThaiFonts;

  final MonthlyScheduleReportMapper mapper;
  final ReportFontLoader _fontLoader;
  final ReportLabels labels;

  static const _notoSansThaiUrl =
      'https://raw.githubusercontent.com/google/fonts/main/'
      'ofl/notosansthai/NotoSansThai%5Bwdth,wght%5D.ttf';
  static Future<({pw.Font regular, pw.Font bold})>? _thaiFonts;

  static Future<({pw.Font regular, pw.Font bold})> _loadThaiFonts() async {
    return _thaiFonts ??= _downloadThaiFonts();
  }

  static Future<({pw.Font regular, pw.Font bold})> _downloadThaiFonts() async {
    final response = await http.get(Uri.parse(_notoSansThaiUrl));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw StateError(
        'Noto Sans Thai font download failed (${response.statusCode}).',
      );
    }
    final data = ByteData.sublistView(response.bodyBytes);
    final regular = pw.Font.ttf(data);
    final bold = pw.Font.ttf(ByteData.sublistView(response.bodyBytes));
    return (regular: regular, bold: bold);
  }

  @override
  Future<Result<Uint8List>> generate(
    Schedule schedule,
    MonthlyReportOptions options,
  ) async {
    try {
      final report = mapper.map(schedule, options);
      final fonts = await _fontLoader();
      final localizedRenderer = MonthlySchedulePdfService(
        mapper: mapper,
        fontLoader: _fontLoader,
        labels: ReportLabels.forLanguageCode(options.languageCode),
      );
      return Success(
        await localizedRenderer.render(report, options, fonts: fonts),
      );
    } on FormatException catch (error, stackTrace) {
      return ValidationFailure(
        'ไม่สามารถจัดเตรียมข้อมูลรายงานได้',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      return PersistenceFailure(
        'ไม่สามารถสร้างไฟล์ PDF ได้',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Renders an already prepared report model.
  Future<Uint8List> render(
    MonthlyScheduleReport report,
    MonthlyReportOptions options, {
    required ({pw.Font regular, pw.Font bold}) fonts,
  }) async {
    final document = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        fontFallback: [fonts.regular],
      ),
    );
    final format = options.orientation == ReportPageOrientation.landscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
    document.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : _continuationHeader(report),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        build: (context) => [
          _header(report),
          pw.SizedBox(height: 10),
          if (report.isEmpty) _emptyState() else _scheduleTable(report),
          if (options.includeLegend && report.legend.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _legend(report),
          ],
          if (options.includeSummary) ...[
            pw.SizedBox(height: 12),
            _summary(report),
          ],
          if (options.includeNotes && report.notes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _notes(report),
          ],
          pw.SizedBox(height: 18),
          _signatures(report),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _header(MonthlyScheduleReport report) {
    final month = DateFormat('MM/yyyy').format(report.metadata.month);
    final generated = DateFormat('dd/MM/yyyy HH:mm')
        .format(report.metadata.generatedAt);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          report.metadata.title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          '${report.metadata.scheduleName} • $month',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        if (report.metadata.departmentName != null)
          pw.Text(
            '${labels.department}: ${report.metadata.departmentName}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        pw.Text(
          '${labels.generatedAt}: $generated',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  pw.Widget _continuationHeader(MonthlyScheduleReport report) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        '${report.metadata.title} — ${report.metadata.scheduleName}',
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _scheduleTable(MonthlyScheduleReport report) {
    final headers = <String>[
      labels.employee,
      labels.department,
      for (final date in report.dates)
        '${date.date.day}\n${date.dayLabel}'
            '${date.holidayName == null ? '' : '\n*'}',
      labels.assignments,
    ];
    final data = <List<String>>[
      headers,
      for (final row in report.rows)
        [
          row.employeeName,
          row.departmentName,
          for (final cell in row.cells) cell.displayValue,
          '${row.assignmentCount}',
        ],
    ];
    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(82),
      1: const pw.FixedColumnWidth(48),
      for (var index = 0; index < report.dates.length; index++)
        index + 2: const pw.FlexColumnWidth(),
      report.dates.length + 2: const pw.FixedColumnWidth(24),
    };
    return pw.TableHelper.fromTextArray(
      data: data,
      headerCount: 1,
      columnWidths: widths,
      cellAlignment: pw.Alignment.center,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 1, vertical: 3),
      cellStyle: const pw.TextStyle(fontSize: 5.2),
      headerStyle: pw.TextStyle(fontSize: 5.5, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.35),
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
    );
  }

  pw.Widget _emptyState() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey500),
      ),
      child: pw.Text(
        labels.noData,
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _legend(MonthlyScheduleReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(labels.legend),
        pw.Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            for (final entry in report.legend)
              pw.Text(
                '${entry.code}: ${entry.name}'
                '${entry.timeLabel == null ? '' : ' (${entry.timeLabel})'}',
                style: const pw.TextStyle(fontSize: 7),
              ),
          ],
        ),
        pw.Text(
          '* วันหยุด • ส./อา. วันสุดสัปดาห์ • '
          'รหัสเวรแสดงเป็นข้อความเพื่อรองรับการพิมพ์ขาวดำ',
          style: const pw.TextStyle(fontSize: 6.5),
        ),
      ],
    );
  }

  pw.Widget _summary(MonthlyScheduleReport report) {
    final statistics = report.statistics;
    final shiftTotals = statistics.assignmentsByShift.entries
        .map((entry) => '${entry.key} ${entry.value}')
        .join(' • ');
    final departmentTotals = statistics.assignmentsByDepartment.entries
        .map((entry) => '${entry.key} ${entry.value}')
        .join(' • ');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(labels.summary),
        pw.Text(
          '${labels.employees}: ${statistics.employeeCount} • '
          '${labels.assignments}: ${statistics.assignmentCount}',
          style: const pw.TextStyle(fontSize: 7),
        ),
        if (shiftTotals.isNotEmpty)
          pw.Text('เวร: $shiftTotals', style: const pw.TextStyle(fontSize: 7)),
        if (departmentTotals.isNotEmpty)
          pw.Text(
            '${labels.department}: $departmentTotals',
            style: const pw.TextStyle(fontSize: 7),
          ),
        if (statistics.reliableWorkingHours != null)
          pw.Text(
            'ชั่วโมงทำงานที่เชื่อถือได้: '
            '${statistics.reliableWorkingHours!.toStringAsFixed(1)}',
            style: const pw.TextStyle(fontSize: 7),
          ),
      ],
    );
  }

  pw.Widget _notes(MonthlyScheduleReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(labels.notes),
        for (final note in report.notes)
          pw.Text('• $note', style: const pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  pw.Widget _signatures(MonthlyScheduleReport report) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (final label in report.signatureLabels)
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 5),
              child: pw.Column(
                children: [
                  pw.Container(
                    height: 22,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                  ),
                  pw.Text(label, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _sectionTitle(String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3),
    child: pw.Text(
      value,
      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
    ),
  );
}
