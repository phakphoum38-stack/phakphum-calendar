import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../application/shift_calendar_workflow_controller.dart';

class WorkflowDashboardScreen extends StatelessWidget {
  const WorkflowDashboardScreen({required this.controller, super.key});

  final ShiftCalendarWorkflowController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final preview = controller.preview;
        final summary = preview?.simulation.summary;

        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.appTitle)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'ตรวจสอบการเปลี่ยนแปลงเวรก่อนลง Google Calendar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (summary == null)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(context.l10n.noScheduleData),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(context.l10n.workflowAddedCount(summary.addCount))),
                    Chip(label: Text(context.l10n.workflowUpdatedCount(summary.updateCount))),
                    Chip(label: Text(context.l10n.workflowDeletedCount(summary.deleteCount))),
                    Chip(label: Text(context.l10n.workflowUnchangedCount(summary.unchangedCount))),
                    Chip(label: Text(context.l10n.workflowWarningCount(summary.warningCount))),
                    Chip(label: Text(context.l10n.workflowBlockedCount(summary.blockedCount))),
                  ],
                ),
              if (controller.message != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(controller.message!),
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: preview == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed:
                          controller.isBusy ||
                              !preview.simulation.summary.canSynchronize ||
                              !preview.simulation.hasChanges
                          ? null
                          : controller.synchronize,
                      icon: controller.isBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calendar_month),
                      label: Text(context.l10n.googleSyncConfirm),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
