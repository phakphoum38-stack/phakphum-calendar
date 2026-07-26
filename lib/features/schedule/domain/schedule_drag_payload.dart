import 'schedule_day.dart';
import 'shift_assignment.dart';

/// Describes a potential assignment move without applying it.
///
/// Persistence and conflict validation can consume this payload in a later
/// sprint without coupling drag gestures to schedule mutations.
class ScheduleDragPayload {
  const ScheduleDragPayload({
    required this.sourceDay,
    required this.assignment,
  });

  final ScheduleDay sourceDay;
  final ShiftAssignment assignment;
}
