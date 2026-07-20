enum ShiftAlertType {
  offAfterNight,
  offConflict,
  shiftOverlap,
  calendarOverlap,
}

enum ShiftAlertDecision { pending, acknowledged, accepted, cancelled }

extension ShiftAlertDecisionInfo on ShiftAlertDecision {
  String get label => switch (this) {
    ShiftAlertDecision.pending => 'รอตัดสินใจ',
    ShiftAlertDecision.acknowledged => 'ยอมรับคำเตือนแล้ว',
    ShiftAlertDecision.accepted => 'ยืนยันรับเวร',
    ShiftAlertDecision.cancelled => 'ยกเลิกแล้ว',
  };
}

class ShiftAlert {
  const ShiftAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.start,
    required this.end,
    required this.decision,
    this.primaryShiftKey,
    this.targetShiftKey,
    this.offShiftKey,
  });

  final String id;
  final ShiftAlertType type;
  final String title;
  final String message;
  final DateTime start;
  final DateTime end;
  final ShiftAlertDecision decision;
  final String? primaryShiftKey;
  final String? targetShiftKey;
  final String? offShiftKey;

  bool get isPending => decision == ShiftAlertDecision.pending;
  bool get isConflict => type != ShiftAlertType.offAfterNight;

  ShiftAlert copyWith({ShiftAlertDecision? decision}) => ShiftAlert(
    id: id,
    type: type,
    title: title,
    message: message,
    start: start,
    end: end,
    decision: decision ?? this.decision,
    primaryShiftKey: primaryShiftKey,
    targetShiftKey: targetShiftKey,
    offShiftKey: offShiftKey,
  );
}
