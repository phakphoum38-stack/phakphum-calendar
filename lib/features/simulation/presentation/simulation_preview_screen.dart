import 'package:flutter/material.dart';

import '../application/simulation_controller.dart';
import '../domain/simulation_item.dart';
import '../domain/simulation_plan.dart';

class SimulationPreviewScreen extends StatelessWidget {
  const SimulationPreviewScreen({
    required this.controller,
    required this.onConfirm,
    super.key,
  });

  final SimulationController controller;
  final Future<void> Function(SimulationPlan plan) onConfirm;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final plan = controller.plan;

        return Scaffold(
          appBar: AppBar(title: const Text('ตรวจสอบก่อนอัปเดต Calendar')),
          body: plan == null
              ? const Center(child: Text('ยังไม่มีผลการเปรียบเทียบ'))
              : Column(
                  children: [
                    _SummaryHeader(plan: plan),
                    Expanded(child: _SimulationList(items: plan.items)),
                  ],
                ),
          bottomNavigationBar: plan == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed:
                          controller.status == SimulationStatus.confirming ||
                              !plan.summary.canSynchronize ||
                              !plan.hasChanges
                          ? null
                          : () => controller.confirm(onConfirm),
                      icon: controller.status == SimulationStatus.confirming
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: const Text('ยืนยันอัปเดต Google Calendar'),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.plan});

  final SimulationPlan plan;

  @override
  Widget build(BuildContext context) {
    final summary = plan.summary;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _SummaryChip(
            label: 'เพิ่ม',
            count: summary.addCount,
            icon: Icons.add_circle_outline,
          ),
          _SummaryChip(
            label: 'แก้ไข',
            count: summary.updateCount,
            icon: Icons.edit_outlined,
          ),
          _SummaryChip(
            label: 'ลบ',
            count: summary.deleteCount,
            icon: Icons.delete_outline,
          ),
          _SummaryChip(
            label: 'ไม่เปลี่ยน',
            count: summary.unchangedCount,
            icon: Icons.check_circle_outline,
          ),
          _SummaryChip(
            label: 'คำเตือน',
            count: summary.warningCount,
            icon: Icons.warning_amber_outlined,
          ),
          _SummaryChip(
            label: 'บล็อก',
            count: summary.blockedCount,
            icon: Icons.block,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.icon,
  });

  final String label;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label $count'));
  }
}

class _SimulationList extends StatelessWidget {
  const _SimulationList({required this.items});

  final List<SimulationItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('ไม่พบรายการเปลี่ยนแปลง'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ListTile(
            leading: Icon(_iconFor(item.action)),
            title: Text(item.title),
            subtitle: Text(
              '${_labelFor(item.action)}\n'
              '${item.start} - ${item.end}\n'
              '${item.reason}',
            ),
            isThreeLine: true,
            trailing: item.warning == null
                ? null
                : const Icon(Icons.warning_amber_outlined),
          ),
        );
      },
    );
  }

  IconData _iconFor(SimulationAction action) {
    return switch (action) {
      SimulationAction.add => Icons.add_circle_outline,
      SimulationAction.update => Icons.edit_outlined,
      SimulationAction.delete => Icons.delete_outline,
      SimulationAction.unchanged => Icons.check_circle_outline,
      SimulationAction.blocked => Icons.block,
    };
  }

  String _labelFor(SimulationAction action) {
    return switch (action) {
      SimulationAction.add => 'เพิ่มกิจกรรม',
      SimulationAction.update => 'แก้ไขกิจกรรม',
      SimulationAction.delete => 'ลบกิจกรรม',
      SimulationAction.unchanged => 'ไม่เปลี่ยนแปลง',
      SimulationAction.blocked => 'ถูกบล็อก',
    };
  }
}
