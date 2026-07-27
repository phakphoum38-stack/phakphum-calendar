import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/utils/calendar_event_matcher.dart';

void main() {
  test('removes trailing source codes from every Calendar title', () {
    expect(CalendarEventMatcher.calendarTitle('GEN เช้า (UG)'), 'GEN เช้า');
    expect(CalendarEventMatcher.calendarTitle('ER ดึก (NER)'), 'ER ดึก');
    expect(CalendarEventMatcher.calendarTitle('On Call'), 'On Call');
  });

  test('matches a legacy event after removing a parenthesized shift code', () {
    expect(
      CalendarEventMatcher.isEquivalent(
        rosterTitle: 'GEN (UG)',
        rosterStart: DateTime(2026, 8, 1, 7, 30),
        rosterEnd: DateTime(2026, 8, 1, 12),
        calendarTitle: 'GEN เช้า',
        calendarStart: DateTime(2026, 8, 1, 7, 30),
        calendarEnd: DateTime(2026, 8, 1, 12),
      ),
      isTrue,
    );
  });

  test('matches the source label at an identical wall-clock range', () {
    expect(
      CalendarEventMatcher.isEquivalent(
        rosterTitle: 'ER ดึก (NER)',
        sourceLabel: 'ER ดึก',
        rosterStart: DateTime(2026, 8, 16),
        rosterEnd: DateTime(2026, 8, 16, 8),
        calendarTitle: 'ER ดึก',
        calendarStart: DateTime(2026, 8, 16),
        calendarEnd: DateTime(2026, 8, 16, 8),
      ),
      isTrue,
    );
  });

  test('does not match unrelated events or different times', () {
    expect(
      CalendarEventMatcher.isEquivalent(
        rosterTitle: 'ER ดึก (NER)',
        rosterStart: DateTime(2026, 8, 16),
        rosterEnd: DateTime(2026, 8, 16, 8),
        calendarTitle: 'ประชุมส่วนตัว',
        calendarStart: DateTime(2026, 8, 16),
        calendarEnd: DateTime(2026, 8, 16, 8),
      ),
      isFalse,
    );
    expect(
      CalendarEventMatcher.isEquivalent(
        rosterTitle: 'ER ดึก (NER)',
        rosterStart: DateTime(2026, 8, 16),
        rosterEnd: DateTime(2026, 8, 16, 8),
        calendarTitle: 'ER ดึก',
        calendarStart: DateTime(2026, 8, 16, 1),
        calendarEnd: DateTime(2026, 8, 16, 9),
      ),
      isFalse,
    );
  });

  test('strict duplicate matching requires the same normalized title', () {
    expect(
      CalendarEventMatcher.isExactEquivalent(
        rosterTitle: 'ER บ่าย',
        rosterStart: DateTime(2026, 9, 1, 16),
        rosterEnd: DateTime(2026, 9, 1, 20),
        calendarTitle: 'ER บ่าย (AER)',
        calendarStart: DateTime(2026, 9, 1, 16),
        calendarEnd: DateTime(2026, 9, 1, 20),
      ),
      isTrue,
    );
    expect(
      CalendarEventMatcher.isExactEquivalent(
        rosterTitle: 'ER บ่าย',
        rosterStart: DateTime(2026, 9, 1, 16),
        rosterEnd: DateTime(2026, 9, 1, 20),
        calendarTitle: 'ER บ่าย นัดส่วนตัว',
        calendarStart: DateTime(2026, 9, 1, 16),
        calendarEnd: DateTime(2026, 9, 1, 20),
      ),
      isFalse,
    );
  });
}
