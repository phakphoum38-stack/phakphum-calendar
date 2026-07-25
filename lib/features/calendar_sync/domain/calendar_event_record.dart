import '../../diff_engine/domain/calendar_event_candidate.dart';

class CalendarEventRecord {
  const CalendarEventRecord({
    required this.providerEventId,
    required this.candidate,
  });

  final String providerEventId;
  final CalendarEventCandidate candidate;
}
