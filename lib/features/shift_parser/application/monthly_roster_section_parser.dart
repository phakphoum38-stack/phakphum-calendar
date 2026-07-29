import '../domain/a1_notation.dart';
import '../domain/monthly_roster_section.dart';
import '../domain/shift_parser_input.dart';
import '../domain/thai_roster_period_parser.dart';

/// Parses repeated monthly roster blocks without requiring known section or
/// row labels. A block is discovered from its numeric date-header row.
class MonthlyRosterSectionParser {
  const MonthlyRosterSectionParser({
    this.periodParser = const ThaiRosterPeriodParser(),
  });

  final ThaiRosterPeriodParser periodParser;
  static const _thaiMonths = <String, int>{
    'มกราคม': 1,
    'กุมภาพันธ์': 2,
    'มีนาคม': 3,
    'เมษายน': 4,
    'พฤษภาคม': 5,
    'มิถุนายน': 6,
    'กรกฎาคม': 7,
    'สิงหาคม': 8,
    'กันยายน': 9,
    'ตุลาคม': 10,
    'พฤศจิกายน': 11,
    'ธันวาคม': 12,
  };

  MonthlyRosterParseReport parse(ShiftParserInput input) {
    final cellsByRow = <int, List<dynamic>>{};
    final cellsByCoordinate = <(int, int), dynamic>{};
    for (final cell in input.cells) {
      cellsByRow.putIfAbsent(cell.rowIndex, () => []).add(cell);
      cellsByCoordinate[(cell.rowIndex, cell.columnIndex)] = cell;
    }

    final headerRows =
        cellsByRow.entries
            .where((entry) => _daysByColumn(entry.value).length >= 7)
            .map((entry) => entry.key)
            .toList()
          ..sort();
    final sections = <MonthlyRosterSection>[];
    final warnings = <String>[];

    for (var index = 0; index < headerRows.length; index++) {
      final headerRow = headerRows[index];
      final daysByColumn = _daysByColumn(cellsByRow[headerRow] ?? const []);
      final nextHeader = index + 1 < headerRows.length
          ? headerRows[index + 1]
          : (cellsByRow.keys.fold<int>(headerRow, (a, b) => a > b ? a : b) + 1);
      final title = _sectionTitle(
        input: input,
        cellsByRow: cellsByRow,
        headerRow: headerRow,
      );

      DateTime start;
      DateTime end;
      try {
        final period = _parsePeriod('$title ${input.sheetTitle}');
        start = period.start;
        end = period.end;
      } on FormatException {
        warnings.add('ไม่พบช่วงเดือนของส่วน "$title"');
        continue;
      }

      final assignments = <MonthlyRosterAssignment>[];
      for (var rowIndex = headerRow + 1; rowIndex < nextHeader; rowIndex++) {
        final rowLabel =
            cellsByCoordinate[(rowIndex, 0)]?.text?.toString().trim() ?? '';
        if (rowLabel.isEmpty || _looksLikeHeading(rowLabel)) continue;

        for (final entry in daysByColumn.entries) {
          final workerCell = cellsByCoordinate[(rowIndex, entry.key)];
          final worker = workerCell?.text?.toString().trim() ?? '';
          if (worker.isEmpty) continue;
          final date = _dateInPeriod(entry.value, start, end);
          if (date == null) continue;
          assignments.add(
            MonthlyRosterAssignment(
              sectionTitle: title,
              rowLabel: rowLabel,
              rowIndex: rowIndex,
              workerName: worker,
              date: date,
              sourceCell: A1Notation.fromZeroBased(
                rowIndex: rowIndex,
                columnIndex: entry.key,
              ),
              backgroundColor: workerCell?.backgroundColor?.hex,
            ),
          );
        }
      }

      sections.add(
        MonthlyRosterSection(
          title: title,
          headerRowIndex: headerRow,
          assignments: List.unmodifiable(assignments),
        ),
      );
    }

    if (headerRows.isEmpty) {
      warnings.add('ไม่พบบล็อกตารางรายเดือนในชีต ${input.sheetTitle}');
    }
    return MonthlyRosterParseReport(
      sections: List.unmodifiable(sections),
      warnings: List.unmodifiable(warnings),
    );
  }

  ThaiRosterPeriod _parsePeriod(String text) {
    try {
      return periodParser.parse(text);
    } on FormatException {
      final monthPattern = _thaiMonths.keys.join('|');
      final match = RegExp(
        '($monthPattern)\\s*(?:พ\\.?\\s*ศ\\.?)?\\s*(\\d{2,4})',
      ).firstMatch(text);
      if (match == null) rethrow;
      var year = int.parse(match.group(2)!);
      if (year < 100) year += 2500;
      if (year >= 2400) year -= 543;
      final month = _thaiMonths[match.group(1)!]!;
      return ThaiRosterPeriod(
        start: DateTime(year, month),
        end: DateTime(year, month + 1, 0),
      );
    }
  }

  Map<int, int> _daysByColumn(List<dynamic> cells) {
    final result = <int, int>{};
    for (final cell in cells) {
      if (cell.columnIndex == 0) continue;
      final value = cell.rawValue ?? cell.text;
      final day = value is num
          ? value.toInt()
          : int.tryParse(value?.toString().trim() ?? '');
      if (day != null && day >= 1 && day <= 31) {
        result[cell.columnIndex as int] = day;
      }
    }
    return result;
  }

  String _sectionTitle({
    required ShiftParserInput input,
    required Map<int, List<dynamic>> cellsByRow,
    required int headerRow,
  }) {
    final candidates = <String>[];
    for (var row = headerRow - 1; row >= 0 && row >= headerRow - 5; row--) {
      final texts = (cellsByRow[row] ?? const [])
          .map((cell) => cell.text?.toString().trim())
          .whereType<String>()
          .where((text) => text.isNotEmpty)
          .toList();
      candidates.addAll(texts);
    }
    final periodTitle = candidates.where((text) => text.contains('ประจำเดือน'));
    if (periodTitle.isNotEmpty) return periodTitle.first;
    final descriptive = candidates.where(
      (text) => text.contains('เวร') || text.contains('คลิน'),
    );
    if (descriptive.isNotEmpty) return descriptive.first;
    return '${input.sheetTitle} แถว ${headerRow + 1}';
  }

  bool _looksLikeHeading(String value) {
    final normalized = value.replaceAll(RegExp(r'\s+'), '');
    return normalized == 'วันที่' || normalized == 'เวร';
  }

  DateTime? _dateInPeriod(int day, DateTime start, DateTime end) {
    for (final base in [start, end]) {
      final candidate = DateTime(base.year, base.month, day);
      if (!candidate.isBefore(start) && !candidate.isAfter(end)) {
        return candidate;
      }
    }
    return null;
  }
}
