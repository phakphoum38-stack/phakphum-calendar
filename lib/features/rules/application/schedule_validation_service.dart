import '../../../domain/entities/employee.dart';
import '../../../domain/entities/schedule.dart';
import '../../../domain/entities/schedule_day.dart';
import '../../../domain/entities/shift_assignment.dart';
import '../domain/rule.dart';
import '../domain/rule_result.dart';
import 'rule_engine.dart';

class ScheduleValidationService {
  ScheduleValidationService({RuleEngine? engine})
    : engine = engine ?? RuleEngine();

  final RuleEngine engine;

  void registerRule(Rule rule) => engine.registerRule(rule);
  bool removeRule(String ruleId) => engine.removeRule(ruleId);
  RuleResult validateSchedule(Schedule schedule) =>
      engine.validateSchedule(schedule);
  RuleResult validateEmployee(Employee employee, Schedule schedule) =>
      engine.validateEmployee(employee, schedule);
  RuleResult validateAssignment(
    ShiftAssignment assignment, {
    required ScheduleDay day,
    Schedule? schedule,
  }) => engine.validateAssignment(assignment, day: day, schedule: schedule);
}
