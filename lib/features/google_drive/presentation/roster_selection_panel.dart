import 'package:flutter/material.dart';

import '../application/roster_selection_controller.dart';
import '../application/roster_selection_state.dart';
import '../domain/roster_file.dart';

class RosterSelectionPanel extends StatelessWidget {
  const RosterSelectionPanel({
    required this.controller,
    required this.onCompare,
    super.key,
  });

  final RosterSelectionController controller;
  final VoidCallback? onCompare;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'เลือกไฟล์ตารางเวร',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _RosterSlotCard(
              title: 'ไฟล์ต้นฉบับ',
              file: controller.selection.original,
              onSelect: () => _showFileDialog(
                context,
                RosterFileSlot.original,
              ),
              onClear: controller.selection.original == null
                  ? null
                  : () => controller.clear(RosterFileSlot.original),
            ),
            const SizedBox(height: 12),
            _RosterSlotCard(
              title: 'ไฟล์ปัจจุบัน',
              file: controller.selection.current,
              onSelect: () => _showFileDialog(
                context,
                RosterFileSlot.current,
              ),
              onClear: controller.selection.current == null
                  ? null
                  : () => controller.clear(RosterFileSlot.current),
            ),
            const SizedBox(height: 20),
            if (controller.errorMessage != null)
              Text(
                controller.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            FilledButton.icon(
              onPressed:
                  controller.selection.canCompare ? onCompare : null,
              icon: const Icon(Icons.compare_arrows),
              label: const Text('เปรียบเทียบไฟล์'),
            ),
            if (controller.selection.original?.id ==
                    controller.selection.current?.id &&
                controller.selection.original != null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'กรุณาเลือกไฟล์ต้นฉบับและไฟล์ปัจจุบันคนละไฟล์',
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showFileDialog(
    BuildContext context,
    RosterFileSlot slot,
  ) async {
    if (controller.availableFiles.isEmpty) {
      await controller.loadSpreadsheets();
    }

    if (!context.mounted || controller.errorMessage != null) {
      return;
    }

    final selected = await showDialog<RosterFile>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          slot == RosterFileSlot.original
              ? 'เลือกไฟล์ต้นฉบับ'
              : 'เลือกไฟล์ปัจจุบัน',
        ),
        content: SizedBox(
          width: 560,
          child: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.availableFiles.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final file = controller.availableFiles[index];
                    return ListTile(
                      leading:
                          const Icon(Icons.table_chart_outlined),
                      title: Text(file.name),
                      subtitle: file.modifiedTime == null
                          ? null
                          : Text(
                              'แก้ไขล่าสุด: ${file.modifiedTime!.toLocal()}',
                            ),
                      onTap: () => Navigator.of(context).pop(file),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ยกเลิก'),
          ),
        ],
      ),
    );

    if (selected != null) {
      controller.select(slot: slot, file: selected);
    }
  }
}

class _RosterSlotCard extends StatelessWidget {
  const _RosterSlotCard({
    required this.title,
    required this.file,
    required this.onSelect,
    required this.onClear,
  });

  final String title;
  final RosterFile? file;
  final VoidCallback onSelect;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.folder_open, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    file?.name ?? 'ยังไม่ได้เลือกไฟล์',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            if (onClear != null)
              IconButton(
                onPressed: onClear,
                tooltip: 'ล้างการเลือก',
                icon: const Icon(Icons.close),
              ),
            OutlinedButton(
              onPressed: onSelect,
              child: const Text('เลือก'),
            ),
          ],
        ),
      ),
    );
  }
}
