import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/access_control/domain/access_control.dart';

void main() {
  test('staff cannot approve shift exchange', () {
    expect(
      AccessPolicy.allows(StaffRole.staff, Permission.approveShiftExchange),
      isFalse,
    );
  });

  test('manager can approve and view audit log', () {
    expect(
      AccessPolicy.allows(StaffRole.manager, Permission.approveShiftExchange),
      isTrue,
    );
    expect(
      AccessPolicy.allows(StaffRole.manager, Permission.viewAuditLog),
      isTrue,
    );
  });
}
