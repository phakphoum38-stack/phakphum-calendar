import 'package:flutter/material.dart';

class CalendarSyncResultCard extends StatelessWidget {
  const CalendarSyncResultCard({
    super.key,
    required this.title,
    required this.isPreview,
    required this.createCount,
    required this.updateCount,
    required this.deleteCount,
    required this.skipCount,
    required this.successCount,
    required this.failureCount,
    required this.appliedCount,
  });

  final String title;
  final bool isPreview;
  final int createCount;
  final int updateCount;
  final int deleteCount;
  final int skipCount;
  final int successCount;
  final int failureCount;
  final int appliedCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasFailure = failureCount > 0;

    return Card(
      key: Key(
        isPreview ? 'calendarSyncPreviewResultCard' : 'calendarSyncResultCard',
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isPreview
                      ? Icons.visibility_outlined
                      : hasFailure
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: hasFailure ? colors.error : colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ResultItem(
                  label: 'สร้าง',
                  value: createCount,
                  icon: Icons.add_circle_outline,
                ),
                _ResultItem(
                  label: 'อัปเดต',
                  value: updateCount,
                  icon: Icons.edit_calendar_outlined,
                ),
                _ResultItem(
                  label: 'ลบ',
                  value: deleteCount,
                  icon: Icons.delete_outline,
                ),
                _ResultItem(
                  label: 'ข้าม',
                  value: skipCount,
                  icon: Icons.skip_next_outlined,
                ),
              ],
            ),
            if (!isPreview) ...[
              const Divider(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ResultItem(
                    label: 'สำเร็จ',
                    value: successCount,
                    icon: Icons.check_circle_outline,
                  ),
                  _ResultItem(
                    label: 'ล้มเหลว',
                    value: failureCount,
                    icon: Icons.error_outline,
                  ),
                  _ResultItem(
                    label: 'ดำเนินการแล้ว',
                    value: appliedCount,
                    icon: Icons.done_all,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultItem extends StatelessWidget {
  const _ResultItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
