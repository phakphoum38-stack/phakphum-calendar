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
    ShiftAlertDecision.acknowledged => 'รับทราบและคงไว้',
    ShiftAlertDecision.accepted => 'ยืนยันรายการ',
    ShiftAlertDecision.cancelled => 'ไม่นำเข้าปฏิทิน',
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
    this.calendarEventId,
    this.calendarEventUrl,
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
  final String? calendarEventId;
  final String? calendarEventUrl;

  bool get requiresDecision => type != ShiftAlertType.offAfterNight;
  bool get isPending =>
      requiresDecision && decision == ShiftAlertDecision.pending;
  bool get isConflict => requiresDecision;
}
