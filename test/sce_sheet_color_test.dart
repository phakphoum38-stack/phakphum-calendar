import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/google_sheets/domain/sheet_color.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/color_mapping.dart';

void main() {
  test('converts RGB components to hexadecimal', () {
    const color = SheetColor(
      red: 1,
      green: 0.5,
      blue: 0,
    );

    expect(color.hex, '#FF8000');
  });

  test('resolves a configured color using tolerance', () {
    const mapping = ShiftColorMapping([
      ShiftColorRule(
        name: 'Example graphite',
        meaning: ShiftColorMeaning.ownShift,
        color: SheetColor(
          red: 0.3,
          green: 0.3,
          blue: 0.3,
        ),
      ),
    ]);

    const candidate = SheetColor(
      red: 0.301,
      green: 0.299,
      blue: 0.3,
    );

    expect(
      mapping.resolve(candidate),
      ShiftColorMeaning.ownShift,
    );
  });
}
