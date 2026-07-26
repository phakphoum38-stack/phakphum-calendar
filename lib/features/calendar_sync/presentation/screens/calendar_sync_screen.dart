import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/account_card.dart';
import '../widgets/calendar_selector.dart';
import '../widgets/calendar_sync_error_card.dart';
import '../widgets/calendar_sync_progress_card.dart';
import '../widgets/calendar_sync_result_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/shift_summary_card.dart';
import '../widgets/sync_action_buttons.dart';

typedef CalendarSyncAction = FutureOr<void> Function();

class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({
    super.key,
    this.accountEmail,
    this.calendarName = 'ยังไม่ได้เลือกปฏิทิน',
    this.selectedMonth,
    this.shiftCount = 0,
    this.isBusy = false,
    this.progress = 0,
    this.progressPercent = 0,
    this.progressMessage = '',
    this.errorMessage,
    this.resultTitle,
    this.resultIsPreview = false,
    this.createCount = 0,
    this.updateCount = 0,
    this.deleteCount = 0,
    this.skipCount = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.appliedCount = 0,
    this.onSelectCalendar,
    this.onSelectMonth,
    this.onPreview,
    this.onSync,
  });

  final String? accountEmail;
  final String calendarName;
  final DateTime? selectedMonth;
  final int shiftCount;
  final bool isBusy;

  final double progress;
  final int progressPercent;
  final String progressMessage;

  final String? errorMessage;

  final String? resultTitle;
  final bool resultIsPreview;
  final int createCount;
  final int updateCount;
  final int deleteCount;
  final int skipCount;
  final int successCount;
  final int failureCount;
  final int appliedCount;

  final VoidCallback? onSelectCalendar;
  final VoidCallback? onSelectMonth;
  final CalendarSyncAction? onPreview;
  final CalendarSyncAction? onSync;

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  bool _isActionRunning = false;

  bool get _isConnected {
    final email = widget.accountEmail?.trim();
    return email != null && email.isNotEmpty;
  }

  bool get _isBusy {
    return widget.isBusy || _isActionRunning;
  }

  bool get _previewEnabled {
    return !_isBusy &&
        _isConnected &&
        widget.selectedMonth != null &&
        widget.onPreview != null;
  }

  bool get _syncEnabled {
    return !_isBusy &&
        _isConnected &&
        widget.selectedMonth != null &&
        widget.shiftCount > 0 &&
        widget.onSync != null;
  }

  Future<void> _runAction({
    required CalendarSyncAction? action,
    required String successMessage,
    required String errorPrefix,
  }) async {
    if (action == null || _isBusy) {
      return;
    }

    setState(() {
      _isActionRunning = true;
    });

    try {
      await Future<void>.sync(action);

      if (!mounted) {
        return;
      }

      _showMessage(message: successMessage, isError: false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(message: '$errorPrefix: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isActionRunning = false;
        });
      }
    }
  }

  void _showMessage({required String message, required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: Key(
            isError
                ? 'calendarSyncErrorSnackBar'
                : 'calendarSyncSuccessSnackBar',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? colors.errorContainer
              : colors.inverseSurface,
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? colors.onErrorContainer
                    : colors.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? colors.onErrorContainer
                        : colors.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _handlePreview() {
    return _runAction(
      action: widget.onPreview,
      successMessage: 'สร้างตัวอย่างรายการเรียบร้อยแล้ว',
      errorPrefix: 'ไม่สามารถสร้างตัวอย่างได้',
    );
  }

  Future<void> _handleSync() {
    return _runAction(
      action: widget.onSync,
      successMessage: 'ซิงก์ปฏิทินเรียบร้อยแล้ว',
      errorPrefix: 'ไม่สามารถซิงก์ปฏิทินได้',
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError =
        widget.errorMessage != null && widget.errorMessage!.trim().isNotEmpty;
    final hasResult =
        widget.resultTitle != null && widget.resultTitle!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('ซิงก์ปฏิทิน')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 32.0 : 16.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AccountCard(
                        email: widget.accountEmail,
                        connected: _isConnected,
                      ),
                      const SizedBox(height: 16),
                      CalendarSelector(
                        calendarName: widget.calendarName,
                        enabled: !_isBusy,
                        onTap: widget.onSelectCalendar,
                      ),
                      const SizedBox(height: 16),
                      MonthSelector(
                        selectedMonth: widget.selectedMonth,
                        enabled: !_isBusy,
                        onTap: widget.onSelectMonth,
                      ),
                      const SizedBox(height: 16),
                      ShiftSummaryCard(shiftCount: widget.shiftCount),
                      if (_isBusy) ...[
                        const SizedBox(height: 16),
                        CalendarSyncProgressCard(
                          progress: widget.progress,
                          percent: widget.progressPercent,
                          message: widget.progressMessage,
                        ),
                      ],
                      if (hasError) ...[
                        const SizedBox(height: 16),
                        CalendarSyncErrorCard(message: widget.errorMessage!),
                      ],
                      if (hasResult) ...[
                        const SizedBox(height: 16),
                        CalendarSyncResultCard(
                          title: widget.resultTitle!,
                          isPreview: widget.resultIsPreview,
                          createCount: widget.createCount,
                          updateCount: widget.updateCount,
                          deleteCount: widget.deleteCount,
                          skipCount: widget.skipCount,
                          successCount: widget.successCount,
                          failureCount: widget.failureCount,
                          appliedCount: widget.appliedCount,
                        ),
                      ],
                      const SizedBox(height: 24),
                      SyncActionButtons(
                        isBusy: _isBusy,
                        previewEnabled: _previewEnabled,
                        syncEnabled: _syncEnabled,
                        onPreview: _handlePreview,
                        onSync: _handleSync,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
