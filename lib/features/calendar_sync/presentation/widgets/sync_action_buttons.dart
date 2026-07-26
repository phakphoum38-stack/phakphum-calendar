import 'package:flutter/material.dart';

class SyncActionButtons extends StatelessWidget {
  const SyncActionButtons({
    super.key,
    required this.isBusy,
    required this.previewEnabled,
    required this.syncEnabled,
    this.onPreview,
    this.onSync,
  });

  final bool isBusy;
  final bool previewEnabled;
  final bool syncEnabled;
  final VoidCallback? onPreview;
  final VoidCallback? onSync;

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return const Column(
        key: Key('calendarSyncBusyView'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8),
          Center(
            child: Text('กำลังประมวลผล...', key: Key('calendarSyncBusyText')),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 480;

        final previewButton = OutlinedButton.icon(
          key: const Key('calendarSyncPreviewButton'),
          onPressed: previewEnabled ? onPreview : null,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('ดูตัวอย่าง'),
        );

        final syncButton = FilledButton.icon(
          key: const Key('calendarSyncButton'),
          onPressed: syncEnabled ? onSync : null,
          icon: const Icon(Icons.sync),
          label: const Text('ซิงก์ปฏิทิน'),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [previewButton, const SizedBox(height: 12), syncButton],
          );
        }

        return Row(
          children: [
            Expanded(child: previewButton),
            const SizedBox(width: 12),
            Expanded(child: syncButton),
          ],
        );
      },
    );
  }
}
