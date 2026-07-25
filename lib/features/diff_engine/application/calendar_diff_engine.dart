import '../domain/calendar_diff.dart';
import '../domain/calendar_event_candidate.dart';

class CalendarDiffEngine {
  const CalendarDiffEngine();

  CalendarDiff compare({
    required List<CalendarEventCandidate> desired,
    required List<CalendarEventCandidate> existing,
  }) {
    _validateUniqueSyncIds(desired, sourceName: 'desired');
    _validateUniqueSyncIds(existing, sourceName: 'existing');

    final desiredById = {for (final event in desired) event.syncId: event};

    final existingById = {for (final event in existing) event.syncId: event};

    final toAdd = <CalendarEventCandidate>[];
    final toUpdate = <CalendarEventCandidate>[];
    final toDelete = <CalendarEventCandidate>[];
    final unchanged = <CalendarEventCandidate>[];

    for (final desiredEvent in desiredById.values) {
      final existingEvent = existingById[desiredEvent.syncId];

      if (!desiredEvent.shouldExist) {
        if (existingEvent != null) {
          toDelete.add(existingEvent);
        }
        continue;
      }

      if (existingEvent == null) {
        toAdd.add(desiredEvent);
        continue;
      }

      if (desiredEvent.contentEquals(existingEvent)) {
        unchanged.add(desiredEvent);
      } else {
        toUpdate.add(desiredEvent);
      }
    }

    for (final existingEvent in existingById.values) {
      if (!desiredById.containsKey(existingEvent.syncId)) {
        toDelete.add(existingEvent);
      }
    }

    _sortByStartAndSyncId(toAdd);
    _sortByStartAndSyncId(toUpdate);
    _sortByStartAndSyncId(toDelete);
    _sortByStartAndSyncId(unchanged);

    return CalendarDiff(
      toAdd: List.unmodifiable(toAdd),
      toUpdate: List.unmodifiable(toUpdate),
      toDelete: List.unmodifiable(toDelete),
      unchanged: List.unmodifiable(unchanged),
    );
  }

  void _validateUniqueSyncIds(
    List<CalendarEventCandidate> events, {
    required String sourceName,
  }) {
    final foundIds = <String>{};

    for (final event in events) {
      final syncId = event.syncId.trim();

      if (syncId.isEmpty) {
        throw ArgumentError(
          '$sourceName contains an event with an empty Sync ID.',
        );
      }

      if (!foundIds.add(syncId)) {
        throw ArgumentError('$sourceName contains duplicate Sync ID: $syncId');
      }
    }
  }

  void _sortByStartAndSyncId(List<CalendarEventCandidate> events) {
    events.sort((left, right) {
      final startComparison = left.start.compareTo(right.start);

      if (startComparison != 0) {
        return startComparison;
      }

      return left.syncId.compareTo(right.syncId);
    });
  }
}
