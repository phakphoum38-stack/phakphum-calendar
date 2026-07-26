/// Prepared metadata displayed at the top of a monthly report.
class ReportMetadata {
  const ReportMetadata({
    required this.title,
    required this.scheduleName,
    required this.month,
    required this.generatedAt,
    this.departmentName,
  });

  final String title;
  final String scheduleName;
  final DateTime month;
  final DateTime generatedAt;
  final String? departmentName;
}

/// One chronological date column in the report grid.
class ReportDateColumn {
  const ReportDateColumn({
    required this.date,
    required this.dayLabel,
    required this.isWeekend,
    this.holidayName,
  });

  final DateTime date;
  final String dayLabel;
  final bool isWeekend;
  final String? holidayName;
}

/// Prepared display value for one employee/date cell.
class ReportScheduleCell {
  const ReportScheduleCell({
    required this.date,
    required this.shiftLabels,
    required this.locations,
    required this.notes,
  });

  final DateTime date;
  final List<String> shiftLabels;
  final List<String> locations;
  final List<String> notes;

  String get displayValue => shiftLabels.join(' / ');
}

/// One deterministic employee row in the monthly report.
class ReportEmployeeRow {
  const ReportEmployeeRow({
    required this.employeeId,
    required this.employeeName,
    required this.departmentId,
    required this.departmentName,
    required this.position,
    required this.cells,
    required this.assignmentCount,
  });

  final String employeeId;
  final String employeeName;
  final String departmentId;
  final String departmentName;
  final String position;
  final List<ReportScheduleCell> cells;
  final int assignmentCount;
}

/// One entry in the printable shift legend.
class ReportShiftLegendEntry {
  const ReportShiftLegendEntry({
    required this.shiftId,
    required this.code,
    required this.name,
    required this.color,
    this.timeLabel,
  });

  final String shiftId;
  final String code;
  final String name;
  final int color;
  final String? timeLabel;
}

/// Aggregated statistics calculated independently from PDF layout.
class ReportStatistics {
  const ReportStatistics({
    required this.employeeCount,
    required this.assignmentCount,
    required this.assignmentsByShift,
    required this.assignmentsByDepartment,
    required this.assignmentsByEmployee,
    this.reliableWorkingHours,
  });

  final int employeeCount;
  final int assignmentCount;
  final Map<String, int> assignmentsByShift;
  final Map<String, int> assignmentsByDepartment;
  final Map<String, int> assignmentsByEmployee;
  final double? reliableWorkingHours;
}

/// Immutable intermediate model consumed by document renderers.
class MonthlyScheduleReport {
  const MonthlyScheduleReport({
    required this.metadata,
    required this.dates,
    required this.rows,
    required this.legend,
    required this.statistics,
    required this.notes,
    required this.signatureLabels,
  });

  final ReportMetadata metadata;
  final List<ReportDateColumn> dates;
  final List<ReportEmployeeRow> rows;
  final List<ReportShiftLegendEntry> legend;
  final ReportStatistics statistics;
  final List<String> notes;
  final List<String> signatureLabels;

  bool get isEmpty => statistics.assignmentCount == 0;
}
