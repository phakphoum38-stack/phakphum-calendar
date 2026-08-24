enum CalendarSyncStage { loading, comparing, planning, executing, completed }

class CalendarSyncProgress {
  const CalendarSyncProgress({
    required this.stage,
    required this.message,
    required this.completed,
    required this.total,
  });

  final CalendarSyncStage stage;
  final String message;
  final int completed;
  final int total;

  double get fraction {
    if (stage == CalendarSyncStage.completed) {
      return 1;
    }

    if (total <= 0) {
      return 0;
    }

    return (completed / total).clamp(0, 1).toDouble();
  }

  bool get isCompleted => stage == CalendarSyncStage.completed;
}

typedef CalendarSyncProgressCallback = void Function(
  CalendarSyncProgress progress,
);
