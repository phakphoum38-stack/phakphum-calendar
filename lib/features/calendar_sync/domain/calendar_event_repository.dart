import 'calendar_event_record.dart';

abstract interface class CalendarEventRepository {
  Future<List<CalendarEventRecord>> listManagedEvents({
    required DateTime timeMin,
    required DateTime timeMax,
  });
}
