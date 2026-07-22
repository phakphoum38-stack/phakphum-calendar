import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/thai_roster_period_parser.dart';

void main() {
  const parser = ThaiRosterPeriodParser();

  test('parses full Thai Buddhist year period', () {
    final period = parser.parse(
      'ประจำเดือน 16 กรกฎาคม พ.ศ. 2569 - 15 สิงหาคม พ.ศ. 2569',
    );
    expect(period.start, DateTime(2026, 7, 16));
    expect(period.end, DateTime(2026, 8, 15));
  });

  test('parses abbreviated month and two-digit Buddhist year', () {
    final period = parser.parse('16 กค69-15 สค.69');
    expect(period.start, DateTime(2026, 7, 16));
    expect(period.end, DateTime(2026, 8, 15));
  });
}
