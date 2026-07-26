import '../../core/result/result.dart';
import '../entities/shift_template.dart';

/// Persistence boundary for configurable shift templates.
abstract interface class ShiftTemplateRepository {
  Future<Result<List<ShiftTemplate>>> findAll({bool activeOnly = true});

  Future<Result<ShiftTemplate?>> findById(String id);

  Future<Result<ShiftTemplate>> save(ShiftTemplate template);

  Future<Result<void>> delete(String id);
}
