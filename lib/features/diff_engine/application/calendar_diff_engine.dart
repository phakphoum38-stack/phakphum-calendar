import '../domain/calendar_diff.dart';
import '../domain/calendar_event_candidate.dart';

class CalendarDiffEngine {
  const CalendarDiffEngine();

  CalendarDiff compare({
    required List<CalendarEventCandidate> desired,
    required List<CalendarEventCandidate> existing,
  }) {
    final desiredById = {
      for (final event in desired) event.syncId: event,
    };
    final existingById = {
      for (final event in existing) event.syncId: event,
    };

    final toAdd = <CalendarEventCandidate>[];
    final toUpdate = <CalendarEventCandidate>[];
    final toDelete = <CalendarEventCandidate>[];
    final unchanged = <CalendarEventCandidate>[];

    for (final entry in desiredById.entries) {
      final existingEvent = existingById[entry.key];
      final desiredEvent = entry.value;

      if (!desiredEvent.shouldExist) {
        if (existingEvent != null) {
          toDelete.add(existingEvent);
        }
        continue;
      }

      if (existingEvent == null) {
        toAdd.add(desiredEvent);
      } else if (!desiredEvent.contentEquals(existingEvent)) {
        toUpdate.add(desiredEvent);
      } else {
        unchanged.add(desiredEvent);
      }
    }

    for (final entry in existingById.entries) {
      if (!desiredById.containsKey(entry.key)) {
        toDelete.add(entry.value);
      }
    }

    return CalendarDiff(
      toAdd: toAdd,
      toUpdate: toUpdate,
      toDelete: toDelete,
      unchanged: unchanged,
    );
  }
}
