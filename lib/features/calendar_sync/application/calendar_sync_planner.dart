import '../../diff_engine/domain/calendar_diff.dart';
import '../domain/calendar_event_record.dart';
import '../domain/calendar_sync_command.dart';

class CalendarSyncPlanner {
  const CalendarSyncPlanner();

  List<CalendarSyncCommand> plan({
    required CalendarDiff diff,
    required List<CalendarEventRecord> existingRecords,
  }) {
    final recordsBySyncId = _indexExistingRecords(existingRecords);
    final commands = <CalendarSyncCommand>[];

    for (final candidate in diff.toAdd) {
      commands.add(CalendarSyncCommand.create(candidate: candidate));
    }

    for (final candidate in diff.toUpdate) {
      final record = _requireExistingRecord(
        recordsBySyncId,
        candidate.syncId,
        actionName: 'update',
      );

      commands.add(
        CalendarSyncCommand.update(
          providerEventId: record.providerEventId,
          candidate: candidate,
        ),
      );
    }

    for (final candidate in diff.toDelete) {
      final record = _requireExistingRecord(
        recordsBySyncId,
        candidate.syncId,
        actionName: 'delete',
      );

      commands.add(
        CalendarSyncCommand.delete(
          providerEventId: record.providerEventId,
          candidate: candidate,
        ),
      );
    }

    for (final candidate in diff.unchanged) {
      final record = recordsBySyncId[candidate.syncId];

      commands.add(
        CalendarSyncCommand.skip(
          providerEventId: record?.providerEventId,
          candidate: candidate,
          reason: 'Event is already up to date.',
        ),
      );
    }

    return List<CalendarSyncCommand>.unmodifiable(commands);
  }

  Map<String, CalendarEventRecord> _indexExistingRecords(
    List<CalendarEventRecord> records,
  ) {
    final recordsBySyncId = <String, CalendarEventRecord>{};

    for (final record in records) {
      final syncId = record.candidate.syncId.trim();
      final providerEventId = record.providerEventId.trim();

      if (syncId.isEmpty) {
        throw ArgumentError(
          'Existing calendar record contains an empty Sync ID.',
        );
      }

      if (providerEventId.isEmpty) {
        throw ArgumentError(
          'Existing calendar record "$syncId" has an empty provider event ID.',
        );
      }

      if (recordsBySyncId.containsKey(syncId)) {
        throw ArgumentError(
          'Existing calendar records contain duplicate Sync ID: $syncId',
        );
      }

      recordsBySyncId[syncId] = record;
    }

    return recordsBySyncId;
  }

  CalendarEventRecord _requireExistingRecord(
    Map<String, CalendarEventRecord> recordsBySyncId,
    String syncId, {
    required String actionName,
  }) {
    final normalizedSyncId = syncId.trim();
    final record = recordsBySyncId[normalizedSyncId];

    if (record == null) {
      throw StateError(
        'Cannot $actionName event "$normalizedSyncId": '
        'no provider event record was found.',
      );
    }

    return record;
  }
}
