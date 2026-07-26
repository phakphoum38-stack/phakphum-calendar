import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/dashboard_summary.dart';

/// Responsive summary-card grid for the SCE dashboard.
class DashboardSummaryGrid extends StatelessWidget {
  const DashboardSummaryGrid({
    required this.summary,
    required this.googleConnected,
    required this.lastSync,
    super.key,
  });

  final DashboardSummary summary;
  final bool googleConnected;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final next = summary.nextAssignment;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final nextDate = summary.nextAssignmentDate;
    final items = [
      _SummaryItem(
        icon: Icons.upcoming_outlined,
        title: context.l10n.myNextShift,
        value: next == null ? context.l10n.noUpcomingShift : next.shift.code,
        detail: next == null
            ? context.l10n.noScheduleData
            : '${next.employee.displayName} • '
                  '${DateFormat.yMMMd(locale).format(nextDate!)}',
      ),
      _SummaryItem(
        icon: Icons.today_outlined,
        title: context.l10n.todaySummary,
        value: '${summary.todayAssignments.length}',
        detail: context.l10n.assignmentCount,
      ),
      _SummaryItem(
        icon: Icons.event_outlined,
        title: context.l10n.tomorrowSummary,
        value: '${summary.tomorrowAssignments.length}',
        detail: context.l10n.assignmentCount,
      ),
      _SummaryItem(
        icon: Icons.calendar_view_month_outlined,
        title: context.l10n.monthlyAssignments,
        value: '${summary.monthAssignmentCount}',
        detail: context.l10n.assignmentCount,
      ),
      _SummaryItem(
        icon: Icons.sync_outlined,
        title: context.l10n.calendarSyncStatus,
        value: googleConnected
            ? context.l10n.connected
            : context.l10n.notConnected,
        detail: lastSync == null
            ? context.l10n.neverSynced
            : DateFormat.yMMMd(locale).add_Hm().format(lastSync!),
      ),
      _SummaryItem(
        icon: Icons.warning_amber_outlined,
        title: context.l10n.conflictWarning,
        value: '${summary.conflictCount}',
        detail: summary.conflictCount == 0
            ? context.l10n.noPendingConflicts
            : context.l10n.requiresReview,
        warning: summary.conflictCount > 0,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _SummaryCard(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    this.warning = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final bool warning;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: item.warning ? scheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(child: Icon(item.icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    item.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
