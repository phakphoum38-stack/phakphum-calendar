enum SimulationAction {
  add,
  update,
  delete,
  unchanged,
  blocked,
}

class SimulationItem {
  const SimulationItem({
    required this.syncId,
    required this.action,
    required this.title,
    required this.start,
    required this.end,
    required this.reason,
    this.sourceSheet,
    this.sourceCell,
    this.warning,
  });

  final String syncId;
  final SimulationAction action;
  final String title;
  final DateTime start;
  final DateTime end;
  final String reason;
  final String? sourceSheet;
  final String? sourceCell;
  final String? warning;
}
