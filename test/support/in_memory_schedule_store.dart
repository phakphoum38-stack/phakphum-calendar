import 'package:phakphum_calendar/features/schedule/data/shared_preferences_schedule_repository.dart';

class InMemoryScheduleKeyValueStore implements ScheduleKeyValueStore {
  final Map<String, String> values = {};
  bool failActivePointerWrites = false;

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failActivePointerWrites && key.endsWith('.active')) {
      throw StateError('Simulated active-pointer failure');
    }
    values[key] = value;
  }
}
