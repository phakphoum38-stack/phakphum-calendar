import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/edition/domain/app_edition.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('edition starts unselected', () async {
    expect(await AppEditionRepository().load(), isNull);
  });

  test('personal and organization editions persist locally', () async {
    final repository = AppEditionRepository();

    await repository.save(AppEdition.personal);
    expect(await repository.load(), AppEdition.personal);

    await repository.save(AppEdition.organization);
    expect(await repository.load(), AppEdition.organization);
  });
}
