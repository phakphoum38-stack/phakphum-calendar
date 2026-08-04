import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/thai_roster_period_parser.dart';

void main() {
  const parser = ThaiRosterPeriodParser();
  const thaiMonths = <String>[
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  test('parses every valid single day of every month from 1900 to 2200', () {
    for (var year = 1900; year <= 2200; year++) {
      final buddhistYear = year + 543;

      for (var month = 1; month <= 12; month++) {
        final monthName = thaiMonths[month - 1];
        final lastDay = DateTime(year, month + 1, 0).day;

        for (var day = 1; day <= lastDay; day++) {
          final source = '$day-$day $monthName $buddhistYear';
          final period = parser.parse(source);
          final expected = DateTime(year, month, day);

          expect(
            period.start,
            expected,
            reason: 'วันเริ่มต้นต้องตรงสำหรับ $source',
          );
          expect(
            period.end,
            expected,
            reason: 'วันสิ้นสุดต้องตรงสำหรับ $source',
          );
        }
      }
    }
  });

  test('shows representative examples for every month in 2569', () {
    final examples = <String, DateTime>{
      '1-1 มกราคม 2569': DateTime(2026, 1, 1),
      '2-2 กุมภาพันธ์ 2569': DateTime(2026, 2, 2),
      '3-3 มีนาคม 2569': DateTime(2026, 3, 3),
      '4-4 เมษายน 2569': DateTime(2026, 4, 4),
      '5-5 พฤษภาคม 2569': DateTime(2026, 5, 5),
      '6-6 มิถุนายน 2569': DateTime(2026, 6, 6),
      '7-7 กรกฎาคม 2569': DateTime(2026, 7, 7),
      '8-8 สิงหาคม 2569': DateTime(2026, 8, 8),
      '9-9 กันยายน 2569': DateTime(2026, 9, 9),
      '10-10 ตุลาคม 2569': DateTime(2026, 10, 10),
      '11-11 พฤศจิกายน 2569': DateTime(2026, 11, 11),
      '12-12 ธันวาคม 2569': DateTime(2026, 12, 12),
    };

    for (final entry in examples.entries) {
      final period = parser.parse(entry.key);
      expect(period.start, entry.value);
      expect(period.end, entry.value);
    }
  });
}
