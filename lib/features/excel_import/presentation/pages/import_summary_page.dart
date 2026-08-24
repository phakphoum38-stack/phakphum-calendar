import 'package:flutter/material.dart';

import '../../../../domain/entities/schedule.dart';
import '../../../../l10n/l10n.dart';
import '../../../../core/result/result.dart';
import '../../../schedule/data/imported_schedule_adapter.dart';
import '../../../schedule/presentation/controllers/schedule_controller.dart';
import '../../../schedule/presentation/pages/imported_month_calendar_page.dart';
import '../../domain/import_summary.dart';
import '../../domain/shift_record.dart';
import '../widgets/import_statistics.dart';
import '../widgets/issue_list.dart';

class ImportSummaryPage extends StatelessWidget {
  const ImportSummaryPage({
    required this.summary,
    required this.records,
    this.schedule,
    this.scheduleControllerFactory,
    this.persistenceResult,
    super.key,
  });

  final ImportSummary summary;
  final List<ShiftRecord> records;
  final Schedule? schedule;
  final ScheduleController Function(Schedule)? scheduleControllerFactory;
  final Result<Schedule>? persistenceResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.importSummary)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.importCompleted,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.importCreatedRecords(
                      records.length,
                      summary.totalRows,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ImportStatistics(summary: summary),
                  if (persistenceResult case Failure<Schedule>(
                    message: final message,
                  )) ...[
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.scheduleSaveFailed(message),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: records.any((record) => record.date != null)
                        ? () => _openCalendar(context)
                        : null,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(context.l10n.viewMonthCalendar),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.issues,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  IssueList(issues: summary.issues),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCalendar(BuildContext context) {
    final canonicalSchedule =
        schedule ?? const ImportedScheduleAdapter().createSchedule(records);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImportedMonthCalendarPage(
          schedule: canonicalSchedule,
          controllerFactory: scheduleControllerFactory,
        ),
      ),
    );
  }
}
