import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/roster_names/domain/roster_name_entry.dart';
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
}
