import 'package:flutter/foundation.dart';

import '../../../core/result/result.dart';
import '../../../domain/entities/shift_template.dart';
import '../../../domain/repositories/shift_template_repository.dart';

/// Owns configurable shift-template state and persistence.
class ShiftTemplateController extends ChangeNotifier {
  ShiftTemplateController({required this.repository});

  final ShiftTemplateRepository repository;
  List<ShiftTemplate> _templates = const [];
  bool _loading = false;
  String? _error;

  List<ShiftTemplate> get templates => _templates;

  bool get loading => _loading;

  String? get error => _error;

  /// Loads templates and creates the standard editable defaults once.
  Future<void> load() async {
    if (_loading) return;
    _setLoading();
    final result = await repository.findAll(activeOnly: false);
    switch (result) {
      case Success<List<ShiftTemplate>>(value: final templates):
        if (templates.isEmpty) {
          await _seedDefaults();
        } else {
          _templates = _ordered(templates);
        }
      case Failure<List<ShiftTemplate>>():
        _error = result.message;
    }
    _loading = false;
    notifyListeners();
  }

  /// Creates or updates one template.
  Future<bool> save(ShiftTemplate template) async {
    _setLoading();
    final result = await repository.save(template);
    switch (result) {
      case Success<ShiftTemplate>():
        final values = List<ShiftTemplate>.of(_templates);
        final index = values.indexWhere((item) => item.id == template.id);
        if (index == -1) {
          values.add(template);
        } else {
          values[index] = template;
        }
        _templates = _ordered(values);
      case Failure<ShiftTemplate>():
        _error = result.message;
    }
    _loading = false;
    notifyListeners();
    return result.isSuccess;
  }

  /// Deactivates a template while preserving existing assignment references.
  Future<bool> deactivate(ShiftTemplate template) {
    return save(template.copyWith(active: false));
  }

  void _setLoading() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  Future<void> _seedDefaults() async {
    final saved = <ShiftTemplate>[];
    for (final template in defaultShiftTemplates) {
      final result = await repository.save(template);
      switch (result) {
        case Success<ShiftTemplate>(value: final value):
          saved.add(value);
        case Failure<ShiftTemplate>():
          _error = result.message;
          _templates = _ordered(saved);
          return;
      }
    }
    _templates = _ordered(saved);
  }

  List<ShiftTemplate> _ordered(Iterable<ShiftTemplate> values) {
    final result = values.toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return List.unmodifiable(result);
  }
}

/// Editable initial catalog supplied only when no templates are persisted.
const defaultShiftTemplates = [
  ShiftTemplate(
    id: 'shift:morning',
    code: 'M',
    name: 'เวรเช้า',
    shortName: 'เช้า',
    startTime: Duration(hours: 8),
    endTime: Duration(hours: 16),
    workingHours: 8,
    color: 0xFF039BE5,
    sortOrder: 0,
  ),
  ShiftTemplate(
    id: 'shift:evening',
    code: 'E',
    name: 'เวรบ่าย',
    shortName: 'บ่าย',
    startTime: Duration(hours: 16),
    endTime: Duration(hours: 24),
    workingHours: 8,
    color: 0xFFF6BF26,
    sortOrder: 1,
  ),
  ShiftTemplate(
    id: 'shift:night',
    code: 'N',
    name: 'เวรดึก',
    shortName: 'ดึก',
    startTime: Duration.zero,
    endTime: Duration(hours: 8),
    workingHours: 8,
    color: 0xFF7986CB,
    sortOrder: 2,
  ),
  ShiftTemplate(
    id: 'shift:on-call',
    code: 'OC',
    name: 'On Call',
    shortName: 'OC',
    startTime: Duration(hours: 17),
    endTime: Duration(hours: 8),
    workingHours: 15,
    color: 0xFF0B8043,
    sortOrder: 3,
  ),
];
