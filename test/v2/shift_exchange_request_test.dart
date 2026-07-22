import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_exchange/domain/shift_exchange_request.dart';

void main() {
  ShiftExchangeRequest pending() => ShiftExchangeRequest(
    id: 'exchange-1',
    organizationId: 'hospital-1',
    departmentId: 'er',
    requesterId: 'staff-a',
    requesterShiftId: 'shift-a',
    targetStaffId: 'staff-b',
    targetShiftId: 'shift-b',
    status: ShiftExchangeStatus.pending,
    createdAt: DateTime(2026, 7, 1),
  );

  test('approves a pending request', () {
    final result = pending().approve(
      approverId: 'manager-1',
      at: DateTime(2026, 7, 2),
    );
    expect(result.status, ShiftExchangeStatus.approved);
    expect(result.decidedBy, 'manager-1');
  });

  test('only requester can cancel', () {
    expect(
      () => pending().cancel(
        actorId: 'staff-b',
        at: DateTime(2026, 7, 2),
      ),
      throwsStateError,
    );
  });
}
