import '../../core/result/result.dart';

abstract interface class SettingsRepository {
  Future<Result<T?>> read<T>(String key);
  Future<Result<void>> write<T>(String key, T value);
  Future<Result<void>> remove(String key);
}
