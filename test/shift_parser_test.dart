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
    p1[17] = 'ผู้ใช้งานทดสอบ';
    p2[18] = 'ผู้ใช้งานทดสอบ';
    ipd[19] = 'ผู้ใช้งานทดสอบ';

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
      targetName: 'ผู้ใช้งานทดสอบ',
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
    genMorning[4] = 'ผู้ใช้งานทดสอบ';
    genAfternoon[5] = 'ผู้ใช้งานทดสอบ';
    floor14[6] = 'ผู้ใช้งานทดสอบ';

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
      targetName: 'ผู้ใช้งานทดสอบ',
      year: 2026,
      month: 8,
    );

    expect(shifts.map((shift) => shift.code), ['UG', 'AG', 'U14']);
    expect(shifts[0].category, ShiftCategory.clinic);
    expect(shifts[0].start, DateTime(2026, 8, 4, 7, 30));
    expect(shifts[1].start, DateTime(2026, 8, 5, 16, 30));
    expect(shifts[2].end, DateTime(2026, 8, 6, 8));
  });

  test('maps bare ER and CT rows in the daytime-duty section', () {
    final days = <Object?>[
      'วันที่',
      ...List.generate(16, (i) => i + 16),
      ...List.generate(15, (i) => i + 1),
    ];
    final er = _row('ER');
    final ct = _row('CT');
    er[8] = 'ผู้ใช้งานทดสอบ';
    ct[9] = 'ผู้ใช้งานทดสอบ';

    final shifts = parser.parse(
      snapshots: [
        SheetSnapshot(
          title: '16 กรกฎาคม 2569 - 15 สิงหาคม 2569',
          rows: [
            days,
            ['เวรกลางวัน'],
            er,
            ct,
          ],
        ),
      ],
      targetName: 'ผู้ใช้งานทดสอบ',
      year: 2026,
      month: 7,
    );

    expect(shifts.map((shift) => shift.code), ['UER', 'UCT']);
    expect(shifts[0].start, DateTime(2026, 7, 23, 8));
    expect(shifts[0].end, DateTime(2026, 7, 23, 16));
    expect(shifts[1].start, DateTime(2026, 7, 24, 8));
    expect(shifts[1].end, DateTime(2026, 7, 24, 16));
  });
}

List<Object?> _row(String label) => <Object?>[label, ...List.filled(31, '')];
