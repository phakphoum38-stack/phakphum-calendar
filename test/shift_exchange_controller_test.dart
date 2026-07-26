import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/shift_exchange/domain/shift_exchange_request.dart';
import 'package:phakphum_calendar/features/shift_exchange/presentation/controllers/shift_exchange_controller.dart';

void main() {
  test('filters requests and preserves deterministic newest-first order', () {
    final controller = ShiftExchangeController(
      requests: [
        _request('older', ShiftExchangeStatus.pending, DateTime(2026, 7, 1)),
        _request('newer', ShiftExchangeStatus.pending, DateTime(2026, 7, 2)),
        _request(
          'approved',
          ShiftExchangeStatus.approved,
          DateTime(2026, 7, 3),
        ),
      ],
    );
    addTearDown(controller.dispose);

    expect(controller.requests.map((request) => request.id), [
      'approved',
      'newer',
      'older',
    ]);

    controller.updateStatus(ShiftExchangeStatus.pending);
    expect(controller.requests.map((request) => request.id), [
      'newer',
      'older',
    ]);
  });
}

ShiftExchangeRequest _request(
  String id,
  ShiftExchangeStatus status,
  DateTime createdAt,
) {
  return ShiftExchangeRequest(
    id: id,
    organizationId: 'org',
    departmentId: 'department',
    requesterId: 'requester',
    requesterShiftId: 'source',
    targetStaffId: 'target',
    targetShiftId: 'replacement',
    status: status,
    createdAt: createdAt,
  );
}
