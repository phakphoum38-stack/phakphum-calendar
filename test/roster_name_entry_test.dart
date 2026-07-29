import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/roster_names/domain/roster_name_entry.dart';
import 'package:phakphum_calendar/features/roster_names/presentation/roster_name_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('roster names and selected status persist locally', () async {
    final repository = RosterNameRepository();
    const entry = RosterNameEntry(
      id: 'person-a',
      name: 'ผู้ใช้ A',
      statuses: ['OFF'],
      lockedDutyPoint: 'CT IPD',
    );

    await repository.saveAll([entry]);
    final loaded = await repository.load();

    expect(loaded.single.id, entry.id);
    expect(loaded.single.name, entry.name);
    expect(loaded.single.statuses, ['OFF']);
    expect(loaded.single.lockedDutyPoint, 'CT IPD');
  });

  test('roster name storage starts empty', () async {
    expect(await RosterNameRepository().load(), isEmpty);
  });

  test('sheet row labels map to daily roster statuses', () {
    expect(rosterStatusFromRowLabel('เวรเช้า'), 'เวร');
    expect(rosterStatusFromRowLabel('เจ้าหน้าที่ OFF'), 'OFF');
    expect(rosterStatusFromRowLabel('แทนเวร'), 'แทนเวร');
    expect(rosterStatusFromRowLabel('ลาป่วย'), 'ลาป่วย');
    expect(rosterStatusFromRowLabel('ลาพักร้อน'), 'ลาพักร้อน');
  });
}
