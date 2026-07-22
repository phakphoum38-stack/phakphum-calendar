import '../domain/calendar_sync_gateway.dart';
import 'calendar_sync_plan.dart';

class CalendarSyncResult {
  const CalendarSyncResult({
    required this.inserted,
    required this.updated,
    required this.deleted,
  });

  final int inserted;
  final int updated;
  final int deleted;
}

class CalendarSyncExecutor {
  const CalendarSyncExecutor(this._gateway);

  final CalendarSyncGateway _gateway;

  Future<CalendarSyncResult> execute(CalendarSyncPlan plan) async {
    var inserted = 0;
    var updated = 0;
    var deleted = 0;

    for (final command in plan.inserts) {
      await _gateway.insert(command);
      inserted++;
    }

    for (final operation in plan.updates) {
      await _gateway.update(
        eventId: operation.eventId,
        command: operation.command,
      );
      updated++;
    }

    for (final operation in plan.deletes) {
      await _gateway.delete(
        eventId: operation.eventId,
        calendarId: operation.calendarId,
      );
      deleted++;
    }

    return CalendarSyncResult(
      inserted: inserted,
      updated: updated,
      deleted: deleted,
    );
  }
}
