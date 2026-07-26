import 'import_issue.dart';

class ImportSummary {
  ImportSummary({
    required this.totalRows,
    required this.importedRows,
    required this.skippedRows,
    required this.errorRows,
    required List<ImportIssue> issues,
  }) : issues = List.unmodifiable(issues);

  final int totalRows;
  final int importedRows;
  final int skippedRows;
  final int errorRows;
  final List<ImportIssue> issues;

  int get warningCount => issues
      .where((issue) => issue.severity == ImportIssueSeverity.warning)
      .length;

  int get errorCount => issues
      .where((issue) => issue.severity == ImportIssueSeverity.error)
      .length;

  double get successPercentage =>
      totalRows == 0 ? 0 : (importedRows / totalRows) * 100;
}
