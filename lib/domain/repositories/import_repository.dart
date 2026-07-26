import '../../core/result/result.dart';
import '../entities/import_profile.dart';

abstract interface class ImportRepository {
  Future<Result<List<ImportProfile>>> findProfiles();
  Future<Result<ImportProfile?>> findProfile(String id);
  Future<Result<ImportProfile>> saveProfile(ImportProfile profile);
  Future<Result<void>> deleteProfile(String id);
}
