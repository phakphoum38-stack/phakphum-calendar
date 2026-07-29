import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_parser/domain/monthly_roster_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'monthly roster templates persist without personal data defaults',
    () async {
      final repository = MonthlyRosterTemplateRepository();
      final template = MonthlyRosterTemplate(
        id: 'monthly-a',
        title: 'เทมเพลต A',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 30),
        groups: const [
          MonthlyRosterShiftGroup(
            id: 'group-a',
            title: 'กลุ่มเช้า',
            rowLabels: ['แถว A', 'แถว B'],
          ),
        ],
      );

      await repository.saveAll([template]);
      final loaded = await repository.load();

      expect(loaded.single.id, template.id);
      expect(loaded.single.title, template.title);
      expect(loaded.single.startDate, DateTime(2026, 9, 1));
      expect(loaded.single.endDate, DateTime(2026, 9, 30));
      expect(loaded.single.groups.single.title, 'กลุ่มเช้า');
      expect(loaded.single.groups.single.rowLabels, ['แถว A', 'แถว B']);
      expect(loaded.single.rowLabels, [
        'กลุ่มเช้า / แถว A',
        'กลุ่มเช้า / แถว B',
      ]);
    },
  );

  test('version 1 templates migrate into the first shift group', () async {
    SharedPreferences.setMockInitialValues({
      MonthlyRosterTemplateRepository.storageKey:
          '{"formatVersion":1,"templates":[{"id":"old","title":"เดิม",'
          '"startDate":"2026-09-01T00:00:00.000",'
          '"endDate":"2026-09-30T00:00:00.000",'
          '"rowLabels":["เช้า","ดึก"]}]}',
    });

    final loaded = await MonthlyRosterTemplateRepository().load();

    expect(loaded.single.groups.single.title, 'กลุ่มเวร 1');
    expect(loaded.single.groups.single.rowLabels, ['เช้า', 'ดึก']);
  });
}
