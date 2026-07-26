/// Page orientation supported by the monthly schedule report.
enum ReportPageOrientation { landscape, portrait }

/// Typed input controlling one deterministic monthly report.
class MonthlyReportOptions {
  const MonthlyReportOptions({
    required this.month,
    required this.generatedAt,
    this.departmentId,
    this.includeSummary = true,
    this.includeNotes = true,
    this.includeLegend = true,
    this.orientation = ReportPageOrientation.landscape,
    this.titleOverride,
    this.languageCode = 'th',
  });

  final DateTime month;
  final DateTime generatedAt;
  final String? departmentId;
  final bool includeSummary;
  final bool includeNotes;
  final bool includeLegend;
  final ReportPageOrientation orientation;
  final String? titleOverride;
  final String languageCode;

  MonthlyReportOptions copyWith({
    DateTime? month,
    DateTime? generatedAt,
    String? departmentId,
    bool clearDepartment = false,
    bool? includeSummary,
    bool? includeNotes,
    bool? includeLegend,
    ReportPageOrientation? orientation,
    String? titleOverride,
    String? languageCode,
  }) {
    return MonthlyReportOptions(
      month: month ?? this.month,
      generatedAt: generatedAt ?? this.generatedAt,
      departmentId: clearDepartment ? null : departmentId ?? this.departmentId,
      includeSummary: includeSummary ?? this.includeSummary,
      includeNotes: includeNotes ?? this.includeNotes,
      includeLegend: includeLegend ?? this.includeLegend,
      orientation: orientation ?? this.orientation,
      titleOverride: titleOverride ?? this.titleOverride,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
