import 'calendar_event_candidate.dart';

class CalendarDiff {
  const CalendarDiff({
    required this.toAdd,
    required this.toUpdate,
    required this.toDelete,
    required this.unchanged,
  });

  final List<CalendarEventCandidate> toAdd;
  final List<CalendarEventCandidate> toUpdate;
  final List<CalendarEventCandidate> toDelete;
  final List<CalendarEventCandidate> unchanged;

  bool get hasChanges =>
      toAdd.isNotEmpty || toUpdate.isNotEmpty || toDelete.isNotEmpty;
}
