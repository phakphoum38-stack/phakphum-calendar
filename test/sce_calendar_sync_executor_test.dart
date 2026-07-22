import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/calendar_engine/application/calendar_sync_executor.dart';
import 'package:phakphum_calendar/features/calendar_engine/application/calendar_sync_plan.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/calendar_sync_command.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/calendar_sync_gateway.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/managed_calendar_event.dart';

class FakeCalendarSyncGateway implements CalendarSyncGateway {
  int inserted = 0;
  int updated = 0;
  int deleted = 0;

  @override
  Future<void> delete({
    required String eventId,
    String calendarId = 'primary',
  }) async {
    deleted++;
  }

  @override
  Future<ManagedCalendarEvent> insert(
    CalendarSyncCommand command,
  ) async {
    inserted++;
    return ManagedCalendarEvent(
      eventId: 'new',
      syncId: command.syncId,
      title: command.title,
      start: command.start,
      end: command.end,
    );
  }

  @override
  Future<List<ManagedCalendarEvent>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  }) async {
    return const [];
  }

  @override
  Future<ManagedCalendarEvent> update({
    required String eventId,
    required CalendarSyncCommand command,
  }) async {
    updated++;
    return ManagedCalendarEvent(
      eventId: eventId,
      syncId: command.syncId,
      title: command.title,
      start: command.start,
      end: command.end,
    );
  }
}

void main() {
  test('executes inserts, updates, and deletes', () async {
    final gateway = FakeCalendarSyncGateway();
    final executor = CalendarSyncExecutor(gateway);
    final start = DateTime(2026, 8, 4, 8);
    final end = DateTime(2026, 8, 4, 16);

    final command = CalendarSyncCommand(
      syncId: 'sync',
      title: 'ER เช้า',
      start: start,
      end: end,
    );

    final result = await executor.execute(
      CalendarSyncPlan(
        inserts: [command],
        updates: [
          CalendarUpdateOperation(
            eventId: 'event-1',
            command: command,
          ),
        ],
        deletes: const [
          CalendarDeleteOperation(
            eventId: 'event-2',
            calendarId: 'primary',
          ),
        ],
      ),
    );

    expect(result.inserted, 1);
    expect(result.updated, 1);
    expect(result.deleted, 1);
    expect(gateway.inserted, 1);
    expect(gateway.updated, 1);
    expect(gateway.deleted, 1);
  });
}
