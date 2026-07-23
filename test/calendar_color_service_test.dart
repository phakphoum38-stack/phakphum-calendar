import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/services/calendar_color_service.dart';

void main() {
  test('accepts color IDs, Thai names and command prefixes', () {
    expect(CalendarColorService.parseCommand('11')?.id, '11');
    expect(CalendarColorService.parseCommand('แดง')?.id, '11');
    expect(CalendarColorService.parseCommand('สี=มะเขือเทศ')?.id, '11');
    expect(CalendarColorService.parseCommand('color: peacock')?.id, '7');
  });

  test('uses the category default when the command is empty', () {
    expect(CalendarColorService.parseCommand(''), isNull);
    expect(CalendarColorService.parseCommand('ค่าเริ่มต้น'), isNull);
  });

  test('rejects unknown color commands before Calendar write', () {
    expect(
      () => CalendarColorService.parseCommand('สีที่ไม่มี'),
      throwsFormatException,
    );
  });
}
