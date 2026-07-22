enum ParseWarningCode {
  missingLayoutProfile,
  unknownShiftDefinition,
  unknownColor,
  missingDate,
  missingName,
  ambiguousRelationship,
  unsupportedCellPattern,
}

class ParseWarning {
  const ParseWarning({
    required this.code,
    required this.message,
    this.sheetTitle,
    this.a1,
  });

  final ParseWarningCode code;
  final String message;
  final String? sheetTitle;
  final String? a1;
}
