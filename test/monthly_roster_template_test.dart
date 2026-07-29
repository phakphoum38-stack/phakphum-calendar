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
        rowLabels: const ['แถว A', 'แถว B'],
      );

      await repository.saveAll([template]);
      final loaded = await repository.load();

      expect(loaded.single.id, template.id);
      expect(loaded.single.title, template.title);
      expect(loaded.single.startDate, DateTime(2026, 9, 1));
      expect(loaded.single.endDate, DateTime(2026, 9, 30));
      expect(loaded.single.rowLabels, ['แถว A', 'แถว B']);
    },
  );
}
