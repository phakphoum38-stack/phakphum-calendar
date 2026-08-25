import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/access_control/domain/access_control.dart';
import 'package:phakphum_calendar/features/admin/domain/admin_access_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('admin access starts unconfigured', () async {
    final config = await AdminAccessRepository().load();

    expect(config.isConfigured, isFalse);
    expect(config.roleFor('user@example.com'), StaffRole.staff);
  });

  test('admin and assigned roles persist locally', () async {
    final repository = AdminAccessRepository();
    const config = AdminAccessConfig(
      users: [
        AdminUserAccess(email: 'admin@example.com', role: StaffRole.admin),
        AdminUserAccess(email: 'manager@example.com', role: StaffRole.manager),
      ],
    );

    await repository.save(config);
    final loaded = await repository.load();

    expect(loaded.isAdmin('ADMIN@example.com'), isTrue);
    expect(loaded.roleFor('manager@example.com'), StaffRole.manager);
    expect(loaded.roleFor('unknown@example.com'), StaffRole.staff);
  });

  test('configuration cannot be saved without an admin', () async {
    const config = AdminAccessConfig(
      users: [
        AdminUserAccess(email: 'staff@example.com', role: StaffRole.staff),
      ],
    );

    expect(
      () => AdminAccessRepository().save(config),
      throwsA(isA<StateError>()),
    );
  });
}
