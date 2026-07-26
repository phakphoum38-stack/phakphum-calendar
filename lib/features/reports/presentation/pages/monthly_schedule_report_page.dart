import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../domain/entities/schedule.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_th.dart';
import '../../domain/monthly_report_options.dart';
import '../controllers/monthly_schedule_report_controller.dart';

/// Production preview and output page for the monthly A4 schedule report.
class MonthlyScheduleReportPage extends StatefulWidget {
  const MonthlyScheduleReportPage({
    super.key,
    required this.schedule,
    required this.controllerFactory,
  });

  final Schedule schedule;
  final MonthlyScheduleReportController Function(Schedule schedule)
  controllerFactory;

  @override
  State<MonthlyScheduleReportPage> createState() =>
      _MonthlyScheduleReportPageState();
}

class _MonthlyScheduleReportPageState extends State<MonthlyScheduleReportPage> {
  late MonthlyScheduleReportController controller = widget.controllerFactory(
    widget.schedule,
  );
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    if (_languageCode != languageCode) {
      _languageCode = languageCode;
      controller.updateOptions(
        controller.options.copyWith(languageCode: languageCode),
      );
    }
  }

  @override
  void didUpdateWidget(covariant MonthlyScheduleReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.schedule, widget.schedule)) {
      controller.dispose();
      controller = widget.controllerFactory(widget.schedule);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ReportControls(controller: controller),
              const SizedBox(height: 12),
              if (controller.error != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(controller.error!),
                  ),
                ),
              Expanded(child: _preview()),
            ],
          ),
        );
      },
    );
  }

  Widget _preview() {
    final bytes = controller.pdfBytes;
    if (controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (bytes == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_outlined, size: 52),
            const SizedBox(height: 12),
            Text(
              widget.schedule.months.isEmpty
                  ? context.reportL10n.reportEmptySchedule
                  : context.reportL10n.reportPreviewPrompt,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: PdfPreview(
        build: (_) async => bytes,
        initialPageFormat:
            controller.options.orientation == ReportPageOrientation.landscape
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4,
        pdfFileName: controller.fileName,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        useActions: false,
      ),
    );
  }
}

class _ReportControls extends StatelessWidget {
  const _ReportControls({required this.controller});

  final MonthlyScheduleReportController controller;

  @override
  Widget build(BuildContext context) {
    final months = controller.availableMonths.isEmpty
        ? [controller.options.month]
        : controller.availableMonths;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<DateTime>(
                key: const Key('report-month'),
                isExpanded: true,
                initialValue: _selectedMonth(months),
                decoration: InputDecoration(
                  labelText: context.reportL10n.month,
                ),
                items: [
                  for (final month in months)
                    DropdownMenuItem(
                      value: month,
                      child: Text(DateFormat('MM/yyyy').format(month)),
                    ),
                ],
                onChanged: controller.loading
                    ? null
                    : (value) {
                        if (value != null) controller.selectMonth(value);
                      },
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                key: const Key('report-department'),
                isExpanded: true,
                initialValue: controller.options.departmentId,
                decoration: InputDecoration(
                  labelText: context.reportL10n.department,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(context.reportL10n.allDepartments),
                  ),
                  for (final department in controller.availableDepartments)
                    DropdownMenuItem<String?>(
                      value: department.id,
                      child: Text(department.name),
                    ),
                ],
                onChanged: controller.loading
                    ? null
                    : controller.selectDepartment,
              ),
            ),
            FilledButton.icon(
              key: const Key('generate-report'),
              onPressed: controller.loading ? null : controller.generate,
              icon: const Icon(Icons.preview_outlined),
              label: Text(context.reportL10n.generatePreview),
            ),
            OutlinedButton.icon(
              key: const Key('print-report'),
              onPressed: controller.loading || !controller.hasPreview
                  ? null
                  : controller.printReport,
              icon: const Icon(Icons.print_outlined),
              label: Text(context.reportL10n.print),
            ),
            OutlinedButton.icon(
              key: const Key('share-report'),
              onPressed: controller.loading || !controller.hasPreview
                  ? null
                  : controller.shareReport,
              icon: const Icon(Icons.save_alt_outlined),
              label: Text(context.reportL10n.saveSharePdf),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _selectedMonth(List<DateTime> months) {
    for (final month in months) {
      if (month.year == controller.options.month.year &&
          month.month == controller.options.month.month) {
        return month;
      }
    }
    return months.first;
  }
}

extension on BuildContext {
  AppLocalizations get reportL10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsTh();
}
