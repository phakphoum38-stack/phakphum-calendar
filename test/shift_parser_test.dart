import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/services/shift_parser.dart';

void main() {
  const parser = ShiftParser();

  test('maps rollover dates and overnight shift times', () {
    final days = <Object?>[
      'เวร',
      ...List.generate(16, (i) => i + 16),
      ...List.generate(15, (i) => i + 1),
    ];
    final p1 = _row('P1 เช้า');
    final p2 = _row('P2 บ่าย');
    final ipd = _row('IPD บ่าย');
    p1[17] = 'ภาคภูมิ';
    p2[18] = 'ภาคภูมิ';
    ipd[19] = 'ภาคภูมิ';

    final shifts = parser.parse(
      snapshots: [
        SheetSnapshot(
          title: '16 กค - 15 สค',
          rows: [
            ['ประจำเดือน 16 กรกฎาคม พ.ศ. 2569 - 15 สิงหาคม พ.ศ. 2569'],
            days,
            p1,
            p2,
            ipd,
          ],
        ),
      ],
      targetName: 'ภาคภูมิ',
      year: 2026,
      month: 8,
    );

    expect(shifts.map((shift) => shift.code), ['UP1', 'AP2', 'AIPD']);
    expect(shifts[0].start, DateTime(2026, 8, 1, 8));
    expect(shifts[1].end, DateTime(2026, 8, 3));
    expect(shifts[2].end, DateTime(2026, 8, 4, 8));
  });

  test('maps GEN morning, GEN afternoon, and 14 floor', () {
    final days = <Object?>['วันที่', ...List.generate(31, (i) => i + 1)];
    final genMorning = _row('GEN');
    final genAfternoon = _row('');
    final floor14 = _row('CT 14 ชั้น');
    genMorning[4] = 'ภาคภูมิ';
    genAfternoon[5] = 'ภาคภูมิ';
    floor14[6] = 'ภาคภูมิ';

    final shifts = parser.parse(
      snapshots: [
        SheetSnapshot(
          title: 'สิงหาคม 2569',
          rows: [
            ['GEN คลินิกพิเศษ (1 สิงหาคม 2569 - 31 สิงหาคม 2569)'],
            days,
            genMorning,
            genAfternoon,
            floor14,
          ],
        ),
      ],
      targetName: 'ภาคภูมิ',
      year: 2026,
      month: 8,
    );

    expect(shifts.map((shift) => shift.code), ['UG', 'AG', 'U14']);
    expect(shifts[0].category, ShiftCategory.clinic);
    expect(shifts[0].start, DateTime(2026, 8, 4, 7, 30));
    expect(shifts[1].start, DateTime(2026, 8, 5, 16, 30));
    expect(shifts[2].end, DateTime(2026, 8, 6, 8));
  });
}

List<Object?> _row(String label) => <Object?>[label, ...List.filled(31, '')];
