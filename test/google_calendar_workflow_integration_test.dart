import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/di/app_dependencies.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/calendar_sync_command.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/calendar_sync_gateway.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/failed_sync_operation.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/failed_sync_repository.dart';
import 'package:phakphum_calendar/features/calendar_engine/domain/managed_calendar_event.dart';
import 'package:phakphum_calendar/features/history/domain/sync_history_entry.dart';
import 'package:phakphum_calendar/features/history/domain/sync_history_repository.dart';
import 'package:phakphum_calendar/features/rules/domain/rule.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_category.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_context.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_severity.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_violation.dart';
import 'package:phakphum_calendar/features/workflow/application/canonical_schedule_event_mapper.dart';

import 'support/canonical_schedule_fixture.dart';

void main() {
  test('canonical validation runs before provider diff generation', () async {
    final calls = <String>[];
    final gateway = _CalendarGateway(calls: calls);
    final dependencies = AppDependencies(
      scheduleRules: [_RecordingRule(calls)],
      syncHistoryRepository: _RecordingHistoryRepository(),
      failedSyncRepository: _InMemoryFailedSyncRepository(),
    );
    final controller = dependencies.createShiftCalendarWorkflowController(
      gateway,
    );
    addTearDown(controller.dispose);

    final schedule = canonicalScheduleFixture();
    await controller.prepareSchedule(schedule);

    expect(controller.schedule, same(schedule));
    expect(calls, ['validate', 'list']);
    expect(controller.schedulePreparation, isNotNull);
    expect(controller.requiresConfirmation, isTrue);
  });

  test('blocking validation prevents diff and execution', () async {
    final calls = <String>[];
    final gateway = _CalendarGateway(calls: calls);
    final dependencies = AppDependencies(
      scheduleRules: const [_BlockingRule()],
      syncHistoryRepository: _RecordingHistoryRepository(),
      failedSyncRepository: _InMemoryFailedSyncRepository(),
    );
    final controller = dependencies.createShiftCalendarWorkflowController(
      gateway,
    );
    addTearDown(controller.dispose);

    await controller.prepareSchedule(canonicalScheduleFixture());
    await controller.synchronize();

    expect(controller.hasBlockingFailures, isTrue);
    expect(controller.schedulePreparation, isNull);
    expect(gateway.executionCount, 0);
    expect(calls, isEmpty);
  });

  test(
    'warnings allow deterministic resilient execution and history',
    () async {
      final gateway = _CalendarGateway();
      final history = _RecordingHistoryRepository();
      final dependencies = AppDependencies(
        scheduleRules: const [_WarningRule()],
        syncHistoryRepository: history,
        failedSyncRepository: _InMemoryFailedSyncRepository(),
      );
      final first = dependencies.createShiftCalendarWorkflowController(gateway);
      final second = dependencies.createShiftCalendarWorkflowController(
        gateway,
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final schedule = canonicalScheduleFixture();

      await first.prepareSchedule(schedule);
      final firstIds = first.schedulePreparation!.plan.inserts
          .map((command) => command.syncId)
          .toList();
      await first.synchronize();

      expect(first.validationResult!.warnings, hasLength(1));
      expect(first.lastResult!.hasFailures, isFalse);
      expect(history.saved.map((entry) => entry.status), [
        SyncHistoryStatus.running,
        SyncHistoryStatus.success,
      ]);

      await second.prepareSchedule(schedule);
      final secondIds = const CanonicalScheduleEventMapper()
          .map(schedule)
          .map((candidate) => candidate.syncId)
          .toList();

      expect(firstIds, secondIds);
      expect(second.schedulePreparation!.plan.operationCount, 0);
    },
  );

  test('partial failures are resumable through the existing service', () async {
    final gateway = _CalendarGateway();
    final history = _RecordingHistoryRepository();
    final failed = _InMemoryFailedSyncRepository();
    final dependencies = AppDependencies(
      scheduleRules: const [],
      syncHistoryRepository: history,
      failedSyncRepository: failed,
    );
    final controller = dependencies.createShiftCalendarWorkflowController(
      gateway,
    );
    addTearDown(controller.dispose);
    final schedule = canonicalScheduleFixture();
    final firstSyncId = const CanonicalScheduleEventMapper()
        .map(schedule)
        .first
        .syncId;
    gateway.failingSyncIds.add(firstSyncId);

    await controller.prepareSchedule(schedule);
    await controller.synchronize();

    final partial = controller.lastResult!.historyEntry;
    expect(partial.status, SyncHistoryStatus.partialSuccess);
    expect(await failed.listForHistory(partial.id), hasLength(1));

    gateway.failingSyncIds.clear();
    final resumed = await controller.resume(partial.id);

    expect(resumed.completed, isTrue);
    expect(resumed.historyEntry.status, SyncHistoryStatus.success);
    expect(await failed.listForHistory(partial.id), isEmpty);
  });

  test('equivalent canonical schedules retain stable sync identifiers', () {
    const mapper = CanonicalScheduleEventMapper();

    final first = mapper.map(canonicalScheduleFixture());
    final second = mapper.map(canonicalScheduleFixture());

    expect(
      first.map((candidate) => candidate.syncId),
      second.map((candidate) => candidate.syncId),
    );
    expect(first.map((candidate) => candidate.syncId).toSet(), hasLength(2));
  });
}

class _CalendarGateway implements CalendarSyncGateway {
  _CalendarGateway({this.calls});

  final List<String>? calls;
  final List<ManagedCalendarEvent> events = [];
  final Set<String> failingSyncIds = {};
  int executionCount = 0;

  @override
  Future<List<ManagedCalendarEvent>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
    String calendarId = 'primary',
  }) async {
    calls?.add('list');
    return List.unmodifiable(events);
  }

  @override
  Future<ManagedCalendarEvent> insert(CalendarSyncCommand command) async {
    executionCount++;
    if (failingSyncIds.contains(command.syncId)) {
      throw StateError('simulated insert failure');
    }
    final event = ManagedCalendarEvent(
      eventId: 'event-${events.length + 1}',
      syncId: command.syncId,
      title: command.title,
      start: command.start,
      end: command.end,
      description: command.description,
    );
    events.add(event);
    return event;
  }

  @override
  Future<ManagedCalendarEvent> update({
    required String eventId,
    required CalendarSyncCommand command,
  }) async {
    executionCount++;
    final event = ManagedCalendarEvent(
      eventId: eventId,
      syncId: command.syncId,
      title: command.title,
      start: command.start,
      end: command.end,
      description: command.description,
    );
    final index = events.indexWhere((item) => item.eventId == eventId);
    if (index >= 0) events[index] = event;
    return event;
  }

  @override
  Future<void> delete({
    required String eventId,
    String calendarId = 'primary',
  }) async {
    executionCount++;
    events.removeWhere((event) => event.eventId == eventId);
  }
}

class _RecordingHistoryRepository implements SyncHistoryRepository {
  final List<SyncHistoryEntry> saved = [];

  @override
  Future<void> save(SyncHistoryEntry entry) async {
    saved.add(entry);
  }

  @override
  Future<SyncHistoryEntry?> findById(String id) async {
    for (final entry in saved.reversed) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<List<SyncHistoryEntry>> list({int limit = 100}) async =>
      saved.reversed.take(limit).toList(growable: false);
}

class _InMemoryFailedSyncRepository implements FailedSyncRepository {
  final Map<String, List<FailedSyncOperation>> values = {};

  @override
  Future<void> clearHistory(String historyId) async {
    values.remove(historyId);
  }

  @override
  Future<List<FailedSyncOperation>> listForHistory(String historyId) async =>
      List.unmodifiable(values[historyId] ?? const []);

  @override
  Future<void> replaceForHistory(
    String historyId,
    List<FailedSyncOperation> operations,
  ) async {
    if (operations.isEmpty) {
      values.remove(historyId);
    } else {
      values[historyId] = List.of(operations);
    }
  }
}

class _RecordingRule implements Rule {
  _RecordingRule(this.calls);

  final List<String> calls;

  @override
  String get id => 'recording';
  @override
  String get name => 'Recording';
  @override
  RuleCategory get category => RuleCategory.custom;
  @override
  RuleSeverity get severity => RuleSeverity.warning;

  @override
  List<RuleViolation> evaluate(RuleContext context) {
    calls.add('validate');
    return const [];
  }
}

class _BlockingRule implements Rule {
  const _BlockingRule();

  @override
  String get id => 'blocking';
  @override
  String get name => 'Blocking';
  @override
  RuleCategory get category => RuleCategory.custom;
  @override
  RuleSeverity get severity => RuleSeverity.error;

  @override
  List<RuleViolation> evaluate(RuleContext context) => const [
    RuleViolation(
      ruleId: 'blocking',
      ruleName: 'Blocking',
      message: 'Blocked',
      severity: RuleSeverity.error,
    ),
  ];
}

class _WarningRule implements Rule {
  const _WarningRule();

  @override
  String get id => 'warning';
  @override
  String get name => 'Warning';
  @override
  RuleCategory get category => RuleCategory.custom;
  @override
  RuleSeverity get severity => RuleSeverity.warning;

  @override
  List<RuleViolation> evaluate(RuleContext context) => const [
    RuleViolation(
      ruleId: 'warning',
      ruleName: 'Warning',
      message: 'Review before sync',
      severity: RuleSeverity.warning,
    ),
  ];
}
