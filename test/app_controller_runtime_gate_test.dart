import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/di/app_dependencies.dart';

void main() {
  test('Calendar writes require explicit confirmation and a prepared preview', () async {
    final controller = AppDependencies.production().createDemoAppController();
    addTearDown(controller.dispose);

    await expectLater(
      controller.syncCalendar(userConfirmed: false),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      controller.syncCalendar(userConfirmed: true),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects overlapping Calendar operations instead of silently dropping them', () async {
    final controller = AppDependencies.production().createDemoAppController();
    addTearDown(controller.dispose);

    // Simulate a roster read or another exclusive controller operation.
    controller.busy = true;

    await expectLater(
      controller.previewCandidates(const []),
      throwsA(isA<StateError>()),
    );
    expect(controller.busy, isTrue);
  });
}
