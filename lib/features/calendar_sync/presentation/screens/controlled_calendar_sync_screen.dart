import 'package:flutter/material.dart';

import '../controllers/calendar_sync_controller.dart';
import 'calendar_sync_screen.dart';

class ControlledCalendarSyncScreen extends StatefulWidget {
  const ControlledCalendarSyncScreen({
    super.key,
    required this.controller,
    this.accountEmail,
    this.calendarName = 'ยังไม่ได้เลือกปฏิทิน',
    this.selectedMonth,
    this.shiftCount = 0,
    this.onSelectCalendar,
    this.onSelectMonth,
  });

  final CalendarSyncController controller;

  final String? accountEmail;
  final String calendarName;
  final DateTime? selectedMonth;
  final int shiftCount;

  final VoidCallback? onSelectCalendar;
  final VoidCallback? onSelectMonth;

  @override
  State<ControlledCalendarSyncScreen> createState() =>
      _ControlledCalendarSyncScreenState();
}

class _ControlledCalendarSyncScreenState
    extends State<ControlledCalendarSyncScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant ControlledCalendarSyncScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    final result = controller.syncResult ?? controller.previewResult;
    final summary = result?.summary;
    final isPreviewResult =
        controller.syncResult == null && controller.previewResult != null;

    String? resultTitle;

    if (controller.syncResult != null) {
      resultTitle = controller.syncResult!.hasFailures
          ? 'ซิงก์เสร็จแล้ว แต่มีบางรายการล้มเหลว'
          : 'ผลการซิงก์ปฏิทิน';
    } else if (controller.previewResult != null) {
      resultTitle = 'ตัวอย่างการเปลี่ยนแปลง';
    }

    return CalendarSyncScreen(
      accountEmail: widget.accountEmail,
      calendarName: widget.calendarName,
      selectedMonth: widget.selectedMonth,
      shiftCount: widget.shiftCount,
      isBusy: controller.isBusy,
      progress: controller.progressFraction,
      progressPercent: controller.progressPercent,
      progressMessage: controller.progressMessage,
      errorMessage: controller.errorMessage,
      resultTitle: resultTitle,
      resultIsPreview: isPreviewResult,
      createCount: summary?.createCount ?? 0,
      updateCount: summary?.updateCount ?? 0,
      deleteCount: summary?.deleteCount ?? 0,
      skipCount: summary?.skipCount ?? 0,
      successCount: summary?.successCount ?? 0,
      failureCount: summary?.failureCount ?? 0,
      appliedCount: summary?.appliedCount ?? 0,
      onSelectCalendar: widget.onSelectCalendar,
      onSelectMonth: widget.onSelectMonth,
      onPreview: controller.preview,
      onSync: controller.sync,
    );
  }
}
