import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/shift_catalog.dart';

void main() {
  test('finds known overnight shift', () {
    final definition = ShiftCatalog.known.find(
      category: 'CT-ER',
      period: 'บ่าย',
    );

    expect(definition, isNotNull);

    final date = DateTime(2026, 8, 4);
    expect(definition!.startFor(date), DateTime(2026, 8, 4, 16));
    expect(definition.endFor(date), DateTime(2026, 8, 5, 8));
  });

  test('returns null for unconfirmed CT shift time', () {
    expect(
      ShiftCatalog.known.find(
        category: 'CT',
        period: 'เช้า',
      ),
      isNull,
    );
  });
}
