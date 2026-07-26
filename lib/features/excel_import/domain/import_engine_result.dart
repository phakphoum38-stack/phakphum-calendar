import 'import_summary.dart';
import 'shift_record.dart';

class ImportEngineResult {
  ImportEngineResult({
    required List<ShiftRecord> records,
    required this.summary,
  }) : records = List.unmodifiable(records);

  final List<ShiftRecord> records;
  final ImportSummary summary;
}
