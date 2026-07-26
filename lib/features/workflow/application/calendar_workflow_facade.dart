import '../../../models/calendar_busy_period.dart';
import '../../../models/roster_period.dart';
import '../../../models/shift.dart';
import '../../../services/calendar_service.dart';
import '../../../services/google_api_client.dart';
import '../../calendar_engine/application/resilient_calendar_sync_executor.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../domain/workflow_preview.dart';
import 'calendar_workflow_factory.dart';
import 'shift_calendar_workflow_controller.dart';

class CalendarWorkflowComparison {
  const CalendarWorkflowComparison({
    required this.preview,
    required this.sourceKeys,
    required this.busyPeriods,
    required this._workflow,
  });

  final WorkflowPreview preview;
  final Set<String> sourceKeys;
  final List<CalendarBusyPeriod> busyPeriods;
  final ShiftCalendarWorkflowController _workflow;
}

class CalendarWorkflowFacade {
  const CalendarWorkflowFacade({
    this._calendarReader = const CalendarService(),
  });

  final CalendarService _calendarReader;

  Future<CalendarWorkflowComparison> compare({
    required GoogleApiClient client,
    required List<Shift> shifts,
    required List<RosterPeriod> periods,
  }) async {
    final snapshot = await _readCalendarPeriods(client, periods);
    final workflow = CalendarWorkflowFactory.create(client: client);
    await workflow.prepareCandidatePreview(desired: _desiredEvents(shifts));
    final preview = workflow.preview;
    if (preview == null) {
      throw StateError('ไม่สามารถเตรียมผลเปรียบเทียบ Calendar ได้');
    }
    return CalendarWorkflowComparison(
      preview: preview,
      sourceKeys: snapshot.sourceKeys,
      busyPeriods: snapshot.busyPeriods,
      workflow: workflow,
    );
  }

  Future<ResilientCalendarSyncResult> synchronizePrepared(
    CalendarWorkflowComparison comparison,
  ) async {
    await comparison._workflow.synchronize();
    final result = comparison._workflow.lastResult;
    if (result == null) {
      throw StateError(
        comparison._workflow.message ?? 'ไม่สามารถซิงก์ Calendar ได้',
      );
    }
    return result;
  }

  List<CalendarEventCandidate> _desiredEvents(List<Shift> shifts) => shifts
      .where((shift) => !shift.excluded)
      .map(
        (shift) => CalendarEventCandidate(
          syncId: CalendarService.keyFor(shift),
          title: CalendarService.summaryFor(shift),
          start: shift.start,
          end: shift.end,
          description: CalendarService.descriptionFor(shift),
          shouldExist: true,
        ),
      )
      .toList(growable: false);

  Future<CalendarReadResult> _readCalendarPeriods(
    GoogleApiClient client,
    List<RosterPeriod> periods,
  ) async {
    final sourceKeys = <String>{};
    final busyByKey = <String, CalendarBusyPeriod>{};
    for (final period in periods) {
      final snapshot = await _calendarReader.readCalendar(
        client,
        year: period.year,
        month: period.month,
      );
      sourceKeys.addAll(snapshot.sourceKeys);
      for (final busy in snapshot.busyPeriods) {
        busyByKey['${busy.id}|${busy.start.toIso8601String()}'] = busy;
      }
    }
    return CalendarReadResult(
      sourceKeys: sourceKeys,
      busyPeriods: busyByKey.values.toList()
        ..sort((left, right) => left.start.compareTo(right.start)),
    );
  }
}
