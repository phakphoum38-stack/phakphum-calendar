enum ImportIssueSeverity { warning, error }

class ImportIssue {
  const ImportIssue({
    required this.rowNumber,
    required this.column,
    required this.message,
    required this.severity,
  });

  final int rowNumber;
  final String column;
  final String message;
  final ImportIssueSeverity severity;
}
