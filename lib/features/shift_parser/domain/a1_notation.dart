abstract final class A1Notation {
  static String fromZeroBased({
    required int rowIndex,
    required int columnIndex,
  }) {
    if (rowIndex < 0 || columnIndex < 0) {
      throw ArgumentError('Row and column indexes must be non-negative.');
    }

    var columnNumber = columnIndex + 1;
    final buffer = StringBuffer();

    while (columnNumber > 0) {
      final remainder = (columnNumber - 1) % 26;
      buffer.writeCharCode(65 + remainder);
      columnNumber = (columnNumber - 1) ~/ 26;
    }

    final columnLetters =
        buffer.toString().split('').reversed.join();

    return '$columnLetters${rowIndex + 1}';
  }
}
