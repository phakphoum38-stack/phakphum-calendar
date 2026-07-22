import '../domain/admin_metrics.dart';

abstract interface class AdminMetricsGateway {
  Future<TenantUsageMetrics> loadTenantMetrics(String tenantId);
}

class AdminDashboardService {
  const AdminDashboardService(this._gateway);

  final AdminMetricsGateway _gateway;

  Future<List<TenantUsageMetrics>> loadPortfolio(
    Iterable<String> tenantIds,
  ) async {
    final metrics = await Future.wait(
      tenantIds.map(_gateway.loadTenantMetrics),
    );
    metrics.sort((left, right) {
      final attentionOrder = (right.requiresAttention ? 1 : 0)
          .compareTo(left.requiresAttention ? 1 : 0);
      if (attentionOrder != 0) return attentionOrder;
      return right.failedSyncOperations.compareTo(left.failedSyncOperations);
    });
    return List.unmodifiable(metrics);
  }
}
