import '../../diff_engine/domain/calendar_diff.dart';
import '../../relationship_engine/domain/user_shift_change.dart';
import '../../simulation/domain/simulation_plan.dart';

class WorkflowPreview {
  const WorkflowPreview({
    required this.changes,
    required this.diff,
    required this.simulation,
    required this.timeMin,
    required this.timeMax,
  });

  final List<UserShiftChange> changes;
  final CalendarDiff diff;
  final SimulationPlan simulation;
  final DateTime timeMin;
  final DateTime timeMax;
}
