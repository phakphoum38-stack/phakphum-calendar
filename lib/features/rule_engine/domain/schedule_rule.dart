import 'package:flutter/foundation.dart';

@immutable
class ScheduledShift {
  const ScheduledShift({
    required this.id,
    required this.staffId,
    required this.start,
    required this.end,
    required this.kind,
  });

  final String id;
  final String staffId;
  final DateTime start;
  final DateTime end;
  final String kind;

  Duration get duration => end.difference(start);
}

enum RuleSeverity { info, warning, blocking }

@immutable
class RuleViolation {
  const RuleViolation({
    required this.ruleId,
    required this.message,
    required this.severity,
    required this.shiftIds,
  });

  final String ruleId;
  final String message;
  final RuleSeverity severity;
  final List<String> shiftIds;
}

abstract interface class ScheduleRule {
  String get id;
  List<RuleViolation> evaluate(List<ScheduledShift> shifts);
}
