import 'package:http/http.dart' as http;

import '../../calendar_engine/application/calendar_sync_plan_builder.dart';
import '../../calendar_engine/application/resilient_calendar_sync_executor.dart';
import '../../calendar_engine/infrastructure/google_calendar_sync_gateway.dart';
import '../../history/domain/sync_history_repository.dart';
import '../../history/infrastructure/in_memory_sync_history_repository.dart';
import 'calendar_sync_coordinator.dart';
import 'shift_calendar_workflow_controller.dart';
import 'workflow_preview_builder.dart';

class CalendarWorkflowFactory {
  const CalendarWorkflowFactory._();

  static ShiftCalendarWorkflowController create({
    required http.Client client,
    SyncHistoryRepository? historyRepository,
    int maxAttempts = 2,
  }) {
    final gateway = GoogleCalendarSyncGateway(client);
    final executor = ResilientCalendarSyncExecutor(
      gateway: gateway,
      historyRepository: historyRepository ?? InMemorySyncHistoryRepository(),
      maxAttempts: maxAttempts,
    );
    return ShiftCalendarWorkflowController(
      previewBuilder: const WorkflowPreviewBuilder(),
      syncCoordinator: CalendarSyncCoordinator(
        gateway: gateway,
        planBuilder: const CalendarSyncPlanBuilder(),
        executor: executor,
      ),
    );
  }
}
