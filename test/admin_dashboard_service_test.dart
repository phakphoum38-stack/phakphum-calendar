import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/admin/application/admin_dashboard_service.dart';
import 'package:phakphum_calendar/features/admin/domain/admin_metrics.dart';

void main() {
  test('places tenants requiring attention first', () async {
    final service = AdminDashboardService(_Gateway());
    final result = await service.loadPortfolio(<String>['healthy', 'warning']);

    expect(result.first.tenantId, 'warning');
    expect(result.first.requiresAttention, isTrue);
  });
}

class _Gateway implements AdminMetricsGateway {
  @override
  Future<TenantUsageMetrics> loadTenantMetrics(String tenantId) async {
    return TenantUsageMetrics(
      tenantId: tenantId,
      activeUsers: 10,
      departments: 2,
      shiftsThisMonth: 100,
      pendingApprovals: tenantId == 'warning' ? 3 : 0,
      failedSyncOperations: tenantId == 'warning' ? 1 : 0,
      generatedAt: DateTime(2026),
    );
  }
}
