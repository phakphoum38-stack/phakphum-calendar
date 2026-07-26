import '../../core/result/result.dart';
import '../entities/schedule_day.dart';
import '../entities/shift_assignment.dart';

abstract interface class NotificationService {
  Future<Result<void>> scheduleAssignmentNotification({
    required ScheduleDay day,
    required ShiftAssignment assignment,
  });

  Future<Result<void>> cancelAssignmentNotification({
    required ScheduleDay day,
    required ShiftAssignment assignment,
  });
}
