import 'package:flutter/foundation.dart';

import '../../../../domain/entities/employee.dart';
import '../../../../domain/entities/schedule.dart';
import '../../application/employee_directory_service.dart';

/// Controls search and filtering for the employee directory.
class EmployeeDirectoryController extends ChangeNotifier {
  EmployeeDirectoryController({
    required Schedule schedule,
    EmployeeDirectoryService service = const EmployeeDirectoryService(),
  }) : this._(schedule, service);

  EmployeeDirectoryController._(this._schedule, this._service);

  Schedule _schedule;
  final EmployeeDirectoryService _service;
  String _query = '';
  String? _departmentId;
  bool _activeOnly = true;

  /// Current free-text search.
  String get query => _query;

  /// Selected department identifier, or null for every department.
  String? get departmentId => _departmentId;

  /// Whether inactive employees are excluded.
  bool get activeOnly => _activeOnly;

  /// Departments represented by the current canonical schedule.
  List<String> get departmentIds {
    final values =
        _service
            .employees(_schedule)
            .map((employee) => employee.department.id)
            .toSet()
            .toList()
          ..sort();
    return List.unmodifiable(values);
  }

  /// Employees matching all active filters.
  List<Employee> get employees => List.unmodifiable(
    _service.employees(_schedule).where((employee) {
      if (_activeOnly && !employee.active) return false;
      if (_departmentId != null && employee.department.id != _departmentId) {
        return false;
      }
      return employee.matches(_query);
    }),
  );

  /// Replaces the schedule source without retaining stale employees.
  void updateSchedule(Schedule schedule) {
    if (identical(_schedule, schedule)) return;
    _schedule = schedule;
    if (_departmentId != null && !departmentIds.contains(_departmentId)) {
      _departmentId = null;
    }
    notifyListeners();
  }

  /// Updates free-text search.
  void updateQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  /// Filters by one department, or clears the filter with null.
  void updateDepartment(String? value) {
    if (_departmentId == value) return;
    _departmentId = value;
    notifyListeners();
  }

  /// Toggles exclusion of inactive employees.
  void updateActiveOnly(bool value) {
    if (_activeOnly == value) return;
    _activeOnly = value;
    notifyListeners();
  }

  /// Restores the default directory filters.
  void clearFilters() {
    if (_query.isEmpty && _departmentId == null && _activeOnly) return;
    _query = '';
    _departmentId = null;
    _activeOnly = true;
    notifyListeners();
  }
}
