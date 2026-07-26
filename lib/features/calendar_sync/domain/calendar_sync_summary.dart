class CalendarSyncSummary {
  const CalendarSyncSummary({
    required this.createCount,
    required this.updateCount,
    required this.deleteCount,
    required this.skipCount,
    required this.successCount,
    required this.failureCount,
    required this.appliedCount,
    required this.executedCount,
    required this.dryRun,
  });

  final int createCount;
  final int updateCount;
  final int deleteCount;
  final int skipCount;

  final int successCount;
  final int failureCount;
  final int appliedCount;
  final int executedCount;

  final bool dryRun;

  int get plannedCount {
    return createCount + updateCount + deleteCount + skipCount;
  }

  int get pendingCount {
    final pending = plannedCount - executedCount;
    return pending < 0 ? 0 : pending;
  }

  bool get hasFailures => failureCount > 0;

  bool get completedAllCommands => executedCount == plannedCount;

  bool get succeeded => !hasFailures && completedAllCommands;
}
