import '../../diff_engine/domain/calendar_diff.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../domain/simulation_item.dart';
import '../domain/simulation_plan.dart';
import '../domain/simulation_summary.dart';

class SimulationPlanBuilder {
  const SimulationPlanBuilder();

  SimulationPlan build({
    required CalendarDiff diff,
    int warningCount = 0,
    int blockedCount = 0,
    DateTime? generatedAt,
  }) {
    final items = <SimulationItem>[
      ...diff.toAdd.map(
        (event) => _item(
          event,
          SimulationAction.add,
          'ไม่พบกิจกรรมเดิมที่มี Sync ID เดียวกัน',
        ),
      ),
      ...diff.toUpdate.map(
        (event) => _item(
          event,
          SimulationAction.update,
          'ข้อมูลเวรเปลี่ยนจากกิจกรรมเดิม',
        ),
      ),
      ...diff.toDelete.map(
        (event) => _item(
          event,
          SimulationAction.delete,
          'เวรนี้ไม่ควรอยู่ในปฏิทินของผู้ใช้อีกต่อไป',
        ),
      ),
      ...diff.unchanged.map(
        (event) =>
            _item(event, SimulationAction.unchanged, 'ข้อมูลตรงกับกิจกรรมเดิม'),
      ),
    ];

    return SimulationPlan(
      items: items,
      summary: SimulationSummary(
        addCount: diff.toAdd.length,
        updateCount: diff.toUpdate.length,
        deleteCount: diff.toDelete.length,
        unchangedCount: diff.unchanged.length,
        warningCount: warningCount,
        blockedCount: blockedCount,
      ),
      generatedAt: generatedAt ?? DateTime.now(),
    );
  }

  SimulationItem _item(
    CalendarEventCandidate event,
    SimulationAction action,
    String reason,
  ) {
    return SimulationItem(
      syncId: event.syncId,
      action: action,
      title: event.title,
      start: event.start,
      end: event.end,
      reason: reason,
    );
  }
}
