import '../../google_sheets/domain/sheet_color.dart';

class NormalizedCell {
  const NormalizedCell({
    required this.sheetId,
    required this.sheetTitle,
    required this.a1,
    required this.rowIndex,
    required this.columnIndex,
    this.text,
    this.rawValue,
    this.backgroundColor,
    this.isMerged = false,
    this.mergedAnchorA1,
  });

  final int sheetId;
  final String sheetTitle;
  final String a1;
  final int rowIndex;
  final int columnIndex;
  final String? text;
  final Object? rawValue;
  final SheetColor? backgroundColor;
  final bool isMerged;
  final String? mergedAnchorA1;
}
