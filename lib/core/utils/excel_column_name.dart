abstract final class ExcelColumnName {
  static String fromIndex(int zeroBasedIndex) {
    if (zeroBasedIndex < 0) {
      throw ArgumentError.value(
        zeroBasedIndex,
        'zeroBasedIndex',
        'Column index must not be negative',
      );
    }
    var value = zeroBasedIndex + 1;
    final letters = StringBuffer();
    while (value > 0) {
      value--;
      letters.writeCharCode(65 + (value % 26));
      value ~/= 26;
    }
    return letters.toString().split('').reversed.join();
  }

  static int toIndex(String columnName) {
    final normalized = columnName.trim().toUpperCase();
    if (normalized.isEmpty ||
        normalized.codeUnits.any((code) => code < 65 || code > 90)) {
      throw FormatException('Invalid Excel column name: $columnName');
    }
    var value = 0;
    for (final code in normalized.codeUnits) {
      value = (value * 26) + (code - 64);
    }
    return value - 1;
  }
}
