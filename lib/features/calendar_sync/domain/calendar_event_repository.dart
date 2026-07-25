import '../../diff_engine/domain/calendar_event_candidate.dart';
import 'calendar_event_record.dart';

abstract interface class CalendarEventRepository {
  Future<List<CalendarEventRecord>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  });

  Future<String> createEvent(CalendarEventCandidate candidate);

  Future<void> updateEvent({
    required String providerEventId,
    required CalendarEventCandidate candidate,
  });

  Future<void> deleteEvent({required String providerEventId});
}
