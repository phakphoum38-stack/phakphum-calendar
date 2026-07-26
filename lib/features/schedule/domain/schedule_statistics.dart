class ScheduleStatistics {
  const ScheduleStatistics({
    required this.totalShifts,
    required this.nightShifts,
    required this.holidayShifts,
    required this.workingHours,
  });

  const ScheduleStatistics.empty()
    : totalShifts = 0,
      nightShifts = 0,
      holidayShifts = 0,
      workingHours = 0;

  final int totalShifts;
  final int nightShifts;
  final int holidayShifts;
  final double workingHours;
}
