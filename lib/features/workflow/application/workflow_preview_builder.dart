import '../../diff_engine/application/calendar_diff_engine.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../../relationship_engine/domain/user_shift_change.dart';
import '../../simulation/application/simulation_plan_builder.dart';
import '../domain/workflow_preview.dart';
import 'user_shift_event_mapper.dart';

class WorkflowPreviewBuilder {
  const WorkflowPreviewBuilder({
    this.mapper = const UserShiftEventMapper(),
    this.diffEngine = const CalendarDiffEngine(),
    this.simulationBuilder = const SimulationPlanBuilder(),
  });

  final UserShiftEventMapper mapper;
  final CalendarDiffEngine diffEngine;
  final SimulationPlanBuilder simulationBuilder;

  WorkflowPreview build({
    required List<UserShiftChange> changes,
    required List<CalendarEventCandidate> existing,
  }) {
    final mapping = mapper.mapChanges(changes);
    final diff = diffEngine.compare(
      desired: mapping.candidates,
      existing: existing,
    );
    final simulation = simulationBuilder.build(
      diff: diff,
      warningCount: mapping.warnings.length,
      blockedCount: mapping.blockedCount,
    );

    final dates = mapping.candidates
        .expand((event) => <DateTime>[event.start, event.end])
        .toList(growable: false);
    final now = DateTime.now();
    final timeMin = dates.isEmpty
        ? DateTime(now.year, now.month, now.day)
        : dates.reduce((left, right) => left.isBefore(right) ? left : right);
    final timeMax = dates.isEmpty
        ? timeMin.add(const Duration(days: 1))
        : dates.reduce((left, right) => left.isAfter(right) ? left : right);

    return WorkflowPreview(
      changes: changes,
      diff: diff,
      simulation: simulation,
      timeMin: timeMin,
      timeMax: timeMax,
    );
  }

  /// Builds a compatibility preview from already mapped event candidates.
  WorkflowPreview buildCandidates({
    required List<CalendarEventCandidate> desired,
    required List<CalendarEventCandidate> existing,
  }) {
    final desiredIds = desired.map((event) => event.syncId).toSet();
    final relevantExisting = existing
        .where((event) => desiredIds.contains(event.syncId))
        .toList(growable: false);
    final diff = diffEngine.compare(
      desired: desired,
      existing: relevantExisting,
    );
    final simulation = simulationBuilder.build(diff: diff);
    final dates = desired
        .expand((event) => <DateTime>[event.start, event.end])
        .toList(growable: false);
    final now = DateTime.now();
    final timeMin = dates.isEmpty
        ? DateTime(now.year, now.month, now.day)
        : dates.reduce((left, right) => left.isBefore(right) ? left : right);
    final timeMax = dates.isEmpty
        ? timeMin.add(const Duration(days: 1))
        : dates.reduce((left, right) => left.isAfter(right) ? left : right);
    return WorkflowPreview(
      changes: const [],
      diff: diff,
      simulation: simulation,
      timeMin: timeMin,
      timeMax: timeMax,
    );
  }
}
