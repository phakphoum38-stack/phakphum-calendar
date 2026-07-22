import 'package:flutter/foundation.dart';

enum ShiftExchangeStatus { pending, approved, rejected, cancelled }

@immutable
class ShiftExchangeRequest {
  const ShiftExchangeRequest({
    required this.id,
    required this.organizationId,
    required this.departmentId,
    required this.requesterId,
    required this.requesterShiftId,
    required this.targetStaffId,
    required this.targetShiftId,
    required this.status,
    required this.createdAt,
    this.decidedBy,
    this.decidedAt,
    this.note,
  });

  final String id;
  final String organizationId;
  final String departmentId;
  final String requesterId;
  final String requesterShiftId;
  final String targetStaffId;
  final String targetShiftId;
  final ShiftExchangeStatus status;
  final DateTime createdAt;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? note;

  bool get isFinal => status != ShiftExchangeStatus.pending;

  ShiftExchangeRequest approve({
    required String approverId,
    required DateTime at,
    String? note,
  }) {
    _ensurePending();
    return _copyDecision(
      status: ShiftExchangeStatus.approved,
      actorId: approverId,
      at: at,
      note: note,
    );
  }

  ShiftExchangeRequest reject({
    required String approverId,
    required DateTime at,
    String? note,
  }) {
    _ensurePending();
    return _copyDecision(
      status: ShiftExchangeStatus.rejected,
      actorId: approverId,
      at: at,
      note: note,
    );
  }

  ShiftExchangeRequest cancel({
    required String actorId,
    required DateTime at,
    String? note,
  }) {
    _ensurePending();
    if (actorId != requesterId) {
      throw StateError('เฉพาะผู้ขอแลกเวรเท่านั้นที่ยกเลิกคำขอได้');
    }
    return _copyDecision(
      status: ShiftExchangeStatus.cancelled,
      actorId: actorId,
      at: at,
      note: note,
    );
  }

  void _ensurePending() {
    if (status != ShiftExchangeStatus.pending) {
      throw StateError('คำขอแลกเวรถูกดำเนินการแล้ว');
    }
  }

  ShiftExchangeRequest _copyDecision({
    required ShiftExchangeStatus status,
    required String actorId,
    required DateTime at,
    String? note,
  }) {
    return ShiftExchangeRequest(
      id: id,
      organizationId: organizationId,
      departmentId: departmentId,
      requesterId: requesterId,
      requesterShiftId: requesterShiftId,
      targetStaffId: targetStaffId,
      targetShiftId: targetShiftId,
      status: status,
      createdAt: createdAt,
      decidedBy: actorId,
      decidedAt: at,
      note: note,
    );
  }
}
