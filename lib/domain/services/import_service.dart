import 'dart:typed_data';

import '../../core/result/result.dart';
import '../entities/import_profile.dart';
import '../entities/shift_assignment.dart';

abstract interface class ImportService {
  Future<Result<List<ShiftAssignment>>> import(
    Uint8List bytes, {
    required ImportProfile profile,
    String? worksheet,
  });
}
