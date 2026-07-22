class SimulationSummary {
  const SimulationSummary({
    required this.addCount,
    required this.updateCount,
    required this.deleteCount,
    required this.unchangedCount,
    required this.warningCount,
    required this.blockedCount,
  });

  final int addCount;
  final int updateCount;
  final int deleteCount;
  final int unchangedCount;
  final int warningCount;
  final int blockedCount;

  bool get canSynchronize => blockedCount == 0;
}
