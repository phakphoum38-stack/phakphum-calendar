import '../../core/result/result.dart';
import '../entities/schedule_month.dart';

abstract interface class CalendarSyncService {
  Future<Result<int>> sync(ScheduleMonth month);
}
