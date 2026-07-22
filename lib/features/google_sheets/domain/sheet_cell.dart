import 'sheet_color.dart';

class SheetCell {
  const SheetCell({
    required this.sheetId,
    required this.rowIndex,
    required this.columnIndex,
    required this.a1,
    this.formattedValue,
    this.rawValue,
    this.formula,
    this.backgroundColor,
    this.numberFormatType,
    this.numberFormatPattern,
    this.isMerged = false,
    this.mergedAnchorA1,
  });

  final int sheetId;
  final int rowIndex;
  final int columnIndex;
  final String a1;
  final String? formattedValue;
  final Object? rawValue;
  final String? formula;
  final SheetColor? backgroundColor;
  final String? numberFormatType;
  final String? numberFormatPattern;
  final bool isMerged;
  final String? mergedAnchorA1;

  bool get isBlank => formattedValue == null || formattedValue!.trim().isEmpty;

  String? get normalizedText {
    final value = formattedValue?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
