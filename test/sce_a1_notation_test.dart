import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/a1_notation.dart';

void main() {
  group('A1Notation', () {
    test('converts zero-based coordinates', () {
      expect(A1Notation.fromZeroBased(rowIndex: 0, columnIndex: 0), 'A1');
      expect(A1Notation.fromZeroBased(rowIndex: 14, columnIndex: 9), 'J15');
      expect(A1Notation.fromZeroBased(rowIndex: 0, columnIndex: 25), 'Z1');
      expect(A1Notation.fromZeroBased(rowIndex: 0, columnIndex: 26), 'AA1');
      expect(A1Notation.fromZeroBased(rowIndex: 99, columnIndex: 701), 'ZZ100');
    });

    test('rejects negative indexes', () {
      expect(
        () => A1Notation.fromZeroBased(rowIndex: -1, columnIndex: 0),
        throwsArgumentError,
      );
    });
  });
}
