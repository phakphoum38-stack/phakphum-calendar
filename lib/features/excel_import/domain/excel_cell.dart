class ExcelCell {
  const ExcelCell({
    required this.rowIndex,
    required this.columnIndex,
    required this.value,
  });

  final int rowIndex;
  final int columnIndex;
  final Object? value;

  String get displayValue => value?.toString() ?? '';
}
