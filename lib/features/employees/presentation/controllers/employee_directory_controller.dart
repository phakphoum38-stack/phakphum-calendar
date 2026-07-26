import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../../../domain/entities/employee.dart';
import '../../../../domain/entities/schedule.dart';
import '../../../../domain/repositories/employee_repository.dart';
import '../../application/employee_directory_service.dart';

/// Controls search and filtering for the employee directory.
class EmployeeDirectoryController extends ChangeNotifier {
  EmployeeDirectoryController({
    required Schedule schedule,
    EmployeeRepository? repository,
    EmployeeDirectoryService service = const EmployeeDirectoryService(),
  }) : this._(schedule, service, repository);

  EmployeeDirectoryController._(
    this._schedule,
    this._service,
    this._repository,
  );

  Schedule _schedule;
  final EmployeeDirectoryService _service;
  final EmployeeRepository? _repository;
  List<Employee> _repositoryEmployees = const [];
  String _query = '';
  String? _departmentId;
  bool _activeOnly = true;
  bool _loading = false;
  String? _error;

  /// Whether repository work is running.
  bool get loading => _loading;

  /// Controlled repository error, if any.
  String? get error => _error;

  /// Current free-text search.
  String get query => _query;

  /// Selected department identifier, or null for every department.
  String? get departmentId => _departmentId;

  /// Whether inactive employees are excluded.
  bool get activeOnly => _activeOnly;

  /// Departments represented by the current canonical schedule.
  List<String> get departmentIds {
    final values =
        _allEmployees.map((employee) => employee.department.id).toSet().toList()
          ..sort();
    return List.unmodifiable(values);
  }

  /// Employees matching all active filters.
  List<Employee> get employees => List.unmodifiable(
    _allEmployees.where((employee) {
      if (_activeOnly && !employee.active) return false;
      if (_departmentId != null && employee.department.id != _departmentId) {
        return false;
      }
      return employee.matches(_query);
    }),
  );

  List<Employee> get _allEmployees {
    final byId = <String, Employee>{
      for (final employee in _service.employees(_schedule))
        employee.id: employee,
      for (final employee in _repositoryEmployees) employee.id: employee,
    };
    final values = byId.values.toList()
      ..sort((left, right) {
        final department = left.department.name.compareTo(
          right.department.name,
        );
        if (department != 0) return department;
        final name = left.displayName.compareTo(right.displayName);
        return name != 0 ? name : left.id.compareTo(right.id);
      });
    return values;
  }

  /// Loads the durable employee directory when configured.
  Future<void> load() async {
    final repository = _repository;
    if (repository == null || _loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await repository.findAll(activeOnly: false);
    switch (result) {
      case Success<List<Employee>>(value: final employees):
        _repositoryEmployees = employees;
      case Failure<List<Employee>>():
        _error = result.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Creates or replaces an employee through the repository.
  Future<bool> saveEmployee(Employee employee) async {
    final repository = _repository;
    if (repository == null) {
      _error = 'Employee persistence is not configured.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    final result = await repository.save(employee);
    switch (result) {
      case Success<Employee>():
        final values = List<Employee>.of(_repositoryEmployees);
        final index = values.indexWhere((item) => item.id == employee.id);
        if (index == -1) {
          values.add(employee);
        } else {
          values[index] = employee;
        }
        _repositoryEmployees = List.unmodifiable(values);
      case Failure<Employee>():
        _error = result.message;
    }
    _loading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Deactivates an employee without deleting historical identity.
  Future<bool> deactivateEmployee(Employee employee) {
    return saveEmployee(employee.copyWith(active: false));
  }

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
