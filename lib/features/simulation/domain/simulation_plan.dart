import 'simulation_item.dart';
import 'simulation_summary.dart';

class SimulationPlan {
  const SimulationPlan({
    required this.items,
    required this.summary,
    required this.generatedAt,
  });

  final List<SimulationItem> items;
  final SimulationSummary summary;
  final DateTime generatedAt;

  bool get hasChanges =>
      summary.addCount > 0 ||
      summary.updateCount > 0 ||
      summary.deleteCount > 0;
}
