import 'dart:typed_data';

import '../../core/result/result.dart';
import '../entities/schedule.dart';

abstract interface class ExportService {
  Future<Result<Uint8List>> export(Schedule schedule);
}
