import 'package:flutter/material.dart';

import '../../domain/schedule_day.dart';
import '../../domain/schedule_drag_payload.dart';
import '../../domain/shift_assignment.dart';

class ScheduleCell extends StatelessWidget {
  const ScheduleCell({
    required this.day,
    required this.assignments,
    super.key,
    this.onTap,
    this.isSelected = false,
    this.isToday = false,
    this.dragEnabled = false,
    this.onAssignmentDrop,
  });

  final ScheduleDay day;
  final List<ShiftAssignment> assignments;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isToday;
  final bool dragEnabled;
  final ValueChanged<ScheduleDragPayload>? onAssignmentDrop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DragTarget<ScheduleDragPayload>(
      onWillAcceptWithDetails: (_) => onAssignmentDrop != null,
      onAcceptWithDetails: (details) => onAssignmentDrop?.call(details.data),
      builder: (context, candidates, _) => Material(
        color: candidates.isNotEmpty
            ? colorScheme.primaryContainer
            : day.isHoliday
            ? colorScheme.errorContainer.withValues(alpha: 0.25)
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isSelected || isToday
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected
                ? 3
                : isToday
                ? 2
                : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${day.date.day}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(width: 4),
                    if (isToday)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _StateLabel(
                              label: 'Today',
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    else if (isSelected)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _StateLabel(
                              label: 'Selected',
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                  ],
                ),
                if (day.isHoliday)
                  Text(
                    day.holidayName ?? 'Holiday',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colorScheme.error),
                  ),
                const SizedBox(height: 6),
                for (final assignment in assignments.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _buildAssignment(assignment),
                  ),
                if (assignments.length > 3)
                  Text(
                    '+${assignments.length - 3} more',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignment(ShiftAssignment assignment) {
    final label = _AssignmentLabel(assignment: assignment);
    if (!dragEnabled) {
      return label;
    }
    return LongPressDraggable<ScheduleDragPayload>(
      data: ScheduleDragPayload(sourceDay: day, assignment: assignment),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(width: 180, child: label),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: label),
      child: label,
    );
  }
}

class _StateLabel extends StatelessWidget {
  const _StateLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _AssignmentLabel extends StatelessWidget {
  const _AssignmentLabel({required this.assignment});

  final ShiftAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final color = Color(assignment.shift.color);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${assignment.shift.code} • ${assignment.employee.nickname.isEmpty ? assignment.employee.firstName : assignment.employee.nickname}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
