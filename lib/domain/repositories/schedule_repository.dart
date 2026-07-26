import '../../core/result/result.dart';
import '../entities/schedule.dart';
import '../entities/schedule_month.dart';

abstract interface class ScheduleRepository {
  Future<Result<Schedule?>> findById(String id);
  Future<Result<ScheduleMonth?>> loadMonth(String scheduleId, DateTime month);
  Future<Result<Schedule>> save(Schedule schedule);
  Future<Result<void>> delete(String id);
}
