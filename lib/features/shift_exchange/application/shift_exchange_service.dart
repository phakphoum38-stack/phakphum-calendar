import '../../access_control/domain/access_control.dart';
import '../../audit/domain/audit_event.dart';
import '../domain/shift_exchange_request.dart';

abstract interface class ShiftExchangeRepository {
  Future<ShiftExchangeRequest?> findById(String id);
  Future<void> save(ShiftExchangeRequest request);
}

class ShiftExchangeService {
  const ShiftExchangeService({
    required this.repository,
    required this.auditRepository,
    required this.clock,
  });

  final ShiftExchangeRepository repository;
  final AuditRepository auditRepository;
  final DateTime Function() clock;

  Future<ShiftExchangeRequest> approve({
    required String requestId,
    required String approverId,
    required StaffRole approverRole,
    String? note,
  }) async {
    if (!AccessPolicy.allows(
      approverRole,
      Permission.approveShiftExchange,
    )) {
      throw StateError('ผู้ใช้นี้ไม่มีสิทธิ์อนุมัติการแลกเวร');
    }

    final request = await repository.findById(requestId);
    if (request == null) throw StateError('ไม่พบคำขอแลกเวร');

    final now = clock();
    final approved = request.approve(
      approverId: approverId,
      at: now,
      note: note,
    );
    await repository.save(approved);
    await auditRepository.append(
      AuditEvent(
        id: 'shift-exchange:$requestId:${now.microsecondsSinceEpoch}',
        organizationId: approved.organizationId,
        actorId: approverId,
        entityType: 'shift_exchange',
        entityId: approved.id,
        action: AuditAction.approved,
        occurredAt: now,
        metadata: {
          'departmentId': approved.departmentId,
          'requesterShiftId': approved.requesterShiftId,
          'targetShiftId': approved.targetShiftId,
        },
      ),
    );
    return approved;
  }
}
