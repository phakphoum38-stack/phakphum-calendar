import 'package:flutter/foundation.dart';

@immutable
class TenantUsageMetrics {
  const TenantUsageMetrics({
    required this.tenantId,
    required this.activeUsers,
    required this.departments,
    required this.shiftsThisMonth,
    required this.pendingApprovals,
    required this.failedSyncOperations,
    required this.generatedAt,
  });

  final String tenantId;
  final int activeUsers;
  final int departments;
  final int shiftsThisMonth;
  final int pendingApprovals;
  final int failedSyncOperations;
  final DateTime generatedAt;

  bool get requiresAttention =>
      pendingApprovals > 0 || failedSyncOperations > 0;
}
