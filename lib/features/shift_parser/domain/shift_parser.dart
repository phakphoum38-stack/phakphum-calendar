import '../../../core/models/shift_record.dart';
import 'shift_parser_input.dart';

class ShiftParseResult {
  const ShiftParseResult({
    required this.records,
    required this.warnings,
  });

  final List<ShiftRecord> records;
  final List<String> warnings;
}

abstract interface class ShiftParser {
  ShiftParseResult parse(ShiftParserInput input);
}
