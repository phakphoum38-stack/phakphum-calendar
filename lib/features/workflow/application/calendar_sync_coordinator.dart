import '../../calendar_engine/application/calendar_sync_plan_builder.dart';
import '../../calendar_engine/application/resilient_calendar_sync_executor.dart';
import '../../calendar_engine/domain/calendar_sync_gateway.dart';
import '../../diff_engine/domain/calendar_diff.dart';

class CalendarSyncCoordinator {
  const CalendarSyncCoordinator({
    required this._gateway,
    required this._planBuilder,
    required this._executor,
  });

  final CalendarSyncGateway _gateway;
  final CalendarSyncPlanBuilder _planBuilder;
  final ResilientCalendarSyncExecutor _executor;

  Future<ResilientCalendarSyncResult> synchronize({
    required CalendarDiff diff,
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  }) async {
    final existing = await _gateway.listManagedEvents(
      timeMin: timeMin,
      timeMax: timeMax,
      calendarId: calendarId,
    );
    final plan = _planBuilder.build(
      diff: diff,
      existingEvents: existing,
      calendarId: calendarId,
    );
    return _executor.execute(plan);
  }
}
