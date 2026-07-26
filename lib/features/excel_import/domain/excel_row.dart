import 'excel_cell.dart';

class ExcelRow {
  ExcelRow({required this.index, required List<ExcelCell> cells})
    : cells = List.unmodifiable(cells);

  final int index;
  final List<ExcelCell> cells;

  bool get isEmpty => cells.every((cell) => cell.displayValue.trim().isEmpty);
}
