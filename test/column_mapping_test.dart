import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/excel_import/domain/column_mapping.dart';

void main() {
  test('supports copy, JSON round-trip, equality, and clearing values', () {
    const mapping = ColumnMapping(
      dateColumn: 'A',
      shiftColumn: 'B',
      employeeColumn: 'C',
      notesColumn: 'F',
    );

    final copied = mapping.copyWith(notesColumn: null, locationColumn: 'E');
    final restored = ColumnMapping.fromJson(copied.toJson());

    expect(copied.dateColumn, 'A');
    expect(copied.notesColumn, isNull);
    expect(copied.locationColumn, 'E');
    expect(restored, copied);
    expect(restored.hashCode, copied.hashCode);
    expect(restored, isNot(mapping));
  });
}
