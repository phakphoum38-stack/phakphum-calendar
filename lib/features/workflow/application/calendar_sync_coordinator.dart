import '../../calendar_engine/application/calendar_sync_plan_builder.dart';
import '../../calendar_engine/application/calendar_sync_plan.dart';
import '../../calendar_engine/application/resilient_calendar_sync_executor.dart';
import '../../calendar_engine/domain/calendar_sync_gateway.dart';
import '../../calendar_engine/domain/managed_calendar_event.dart';
import '../../../core/utils/calendar_event_matcher.dart';
import '../../../domain/entities/schedule.dart';
import '../../diff_engine/application/calendar_diff_engine.dart';
import '../../diff_engine/domain/calendar_diff.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import 'canonical_schedule_event_mapper.dart';

/// Immutable provider comparison prepared before user confirmation.
class CalendarSyncPreparation {
  const CalendarSyncPreparation({
    required this.diff,
    required this.plan,
    required this.timeMin,
    required this.timeMax,
  });

  final CalendarDiff diff;
  final CalendarSyncPlan plan;
  final DateTime timeMin;
  final DateTime timeMax;
}

class CalendarSyncCoordinator {
  const CalendarSyncCoordinator({
    required this._gateway,
    required this._planBuilder,
    required this._executor,
    this.scheduleMapper = const CanonicalScheduleEventMapper(),
    this.diffEngine = const CalendarDiffEngine(),
  });

  final CalendarSyncGateway _gateway;
  final CalendarSyncPlanBuilder _planBuilder;
  final ResilientCalendarSyncExecutor _executor;
  final CanonicalScheduleEventMapper scheduleMapper;
  final CalendarDiffEngine diffEngine;

  /// Builds a deterministic diff and plan directly from a canonical schedule.
  Future<CalendarSyncPreparation> prepareSchedule(
    Schedule schedule, {
    String calendarId = 'primary',
  }) async {
    final desired = scheduleMapper.map(schedule);
    final range = _range(desired);
    final managed = await _gateway.listManagedEvents(
      timeMin: range.$1,
      timeMax: range.$2,
      calendarId: calendarId,
    );
    final comparableGateway = _gateway is ComparableCalendarEventGateway
        ? _gateway as ComparableCalendarEventGateway
        : null;
    final legacy = comparableGateway == null
        ? const <ManagedCalendarEvent>[]
        : await comparableGateway.listComparableLegacyEvents(
            timeMin: range.$1,
            timeMax: range.$2,
            calendarId: calendarId,
          );
    final adopted = _adoptEquivalentLegacy(desired, managed, legacy);
    final existing = adopted.map(_candidateFromManaged).toList(growable: false);
    final diff = diffEngine.compare(desired: desired, existing: existing);
    final plan = _planBuilder.build(
      diff: diff,
      existingEvents: adopted,
      calendarId: calendarId,
    );
    return CalendarSyncPreparation(
      diff: diff,
      plan: plan,
      timeMin: range.$1,
      timeMax: range.$2,
    );
  }

  /// Executes a plan that was prepared before user confirmation.
  Future<ResilientCalendarSyncResult> execute(
    CalendarSyncPreparation preparation,
  ) {
    return _executor.execute(preparation.plan);
  }

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

  /// Reads managed provider events for a pre-mapped compatibility workflow.
  Future<List<CalendarEventCandidate>> listExistingCandidates(
    List<CalendarEventCandidate> desired, {
    String calendarId = 'primary',
  }) async {
    final range = _range(desired);
    final managed = await _gateway.listManagedEvents(
      timeMin: range.$1,
      timeMax: range.$2,
      calendarId: calendarId,
    );
    return managed.map(_candidateFromManaged).toList(growable: false);
  }

  (DateTime, DateTime) _range(List<CalendarEventCandidate> candidates) {
    final now = DateTime.now();
    if (candidates.isEmpty) {
      final start = DateTime(now.year, now.month, now.day);
      return (start, start.add(const Duration(days: 1)));
    }
    final starts = candidates.map((candidate) => candidate.start);
    final ends = candidates.map((candidate) => candidate.end);
    final timeMin = starts.reduce(
      (left, right) => left.isBefore(right) ? left : right,
    );
    final timeMax = ends.reduce(
      (left, right) => left.isAfter(right) ? left : right,
    );
    return (timeMin, timeMax);
  }

  CalendarEventCandidate _candidateFromManaged(ManagedCalendarEvent event) {
    return CalendarEventCandidate(
      syncId: event.syncId,
      title: event.title,
      start: event.start,
      end: event.end,
      shouldExist: true,
      description: event.description,
      colorId: event.colorId,
    );
  }

  List<ManagedCalendarEvent> _adoptEquivalentLegacy(
    List<CalendarEventCandidate> desired,
    List<ManagedCalendarEvent> managed,
    List<ManagedCalendarEvent> legacy,
  ) {
    final result = <ManagedCalendarEvent>[...managed];
    final managedIds = managed.map((event) => event.syncId).toSet();
    final adoptedProviderIds = <String>{};
    for (final candidate in desired) {
      if (managedIds.contains(candidate.syncId)) {
        final obsoleteDuplicates = legacy.where(
          (event) =>
              !adoptedProviderIds.contains(event.eventId) &&
              CalendarEventMatcher.isExactEquivalent(
                rosterTitle: candidate.title,
                rosterStart: candidate.start,
                rosterEnd: candidate.end,
                calendarTitle: event.title,
                calendarStart: event.start,
                calendarEnd: event.end,
              ),
        );
        for (final duplicate in obsoleteDuplicates) {
          adoptedProviderIds.add(duplicate.eventId);
          result.add(duplicate);
        }
        continue;
      }
      final matches = legacy
          .where(
            (event) =>
                !adoptedProviderIds.contains(event.eventId) &&
                CalendarEventMatcher.isEquivalent(
                  rosterTitle: candidate.title,
                  rosterStart: candidate.start,
                  rosterEnd: candidate.end,
                  calendarTitle: event.title,
                  calendarStart: event.start,
                  calendarEnd: event.end,
                ),
          )
          .toList(growable: false);
      if (matches.length != 1) continue;
      final event = matches.single;
      adoptedProviderIds.add(event.eventId);
      result.add(
        ManagedCalendarEvent(
          eventId: event.eventId,
          syncId: candidate.syncId,
          title: event.title,
          start: event.start,
          end: event.end,
          description: event.description,
          colorId: event.colorId,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}
