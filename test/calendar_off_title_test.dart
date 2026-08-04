import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/utils/calendar_event_matcher.dart';

void main() {
  test('shows generated off-duty event as ออฟ only', () {
    expect(
      CalendarEventMatcher.calendarTitle('OFF — เวรออฟหลังเวรดึก'),
      'ออฟ',
    );
    expect(CalendarEventMatcher.calendarTitle('เวรออฟหลังเวรดึก'), 'ออฟ');
  });

  test('does not change normal shift titles', () {
    expect(CalendarEventMatcher.calendarTitle('ER ดึก (NER)'), 'ER ดึก');
  });
}
