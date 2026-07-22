import '../domain/a1_notation.dart';
import '../domain/roster_cell_assignment.dart';
import '../domain/roster_parse_report.dart';
import '../domain/shift_parser_input.dart';
import '../domain/thai_roster_period_parser.dart';

class HospitalRosterParser {
  const HospitalRosterParser({
    ThaiRosterPeriodParser periodParser = const ThaiRosterPeriodParser(),
  }) : _periodParser = periodParser;

  final ThaiRosterPeriodParser _periodParser;

  RosterParseReport parse(ShiftParserInput input) {
    final byCoordinate = <(int, int), dynamic>{
      for (final cell in input.cells) (cell.rowIndex, cell.columnIndex): cell,
    };

    final periodText = input.cells
        .map((cell) => cell.text)
        .whereType<String>()
        .firstWhere(
          (text) =>
              text.contains('ประจำเดือน') ||
              (text.contains('16') && text.contains('15')),
          orElse: () => input.sheetTitle,
        );
    final period = _periodParser.parse(periodText);

    final dateHeaderRow = _findDateHeaderRow(input);
    final dayByColumn = <int, int>{};
    for (final cell in input.cells.where((c) => c.rowIndex == dateHeaderRow)) {
      final day = _asDay(cell.rawValue ?? cell.text);
      if (day != null && cell.columnIndex > 0) {
        dayByColumn[cell.columnIndex] = day;
      }
    }

    final assignments = <RosterCellAssignment>[];
    final warnings = <String>[];

    for (final rowLabelCell in input.cells.where(
      (cell) => cell.columnIndex == 0 && cell.text != null,
    )) {
      final definition = _parseRowLabel(rowLabelCell.text!);
      if (definition == null) continue;

      for (final entry in dayByColumn.entries) {
        final workerCell = byCoordinate[(rowLabelCell.rowIndex, entry.key)];
        final worker = workerCell?.text?.trim();
        if (worker == null || worker.isEmpty) continue;

        final date = _resolveDate(
          day: entry.value,
          start: period.start,
          end: period.end,
        );

        assignments.add(
          RosterCellAssignment(
            spreadsheetId: input.spreadsheetId,
            sheetId: input.sheetId,
            sheetTitle: input.sheetTitle,
            sourceCell: A1Notation.fromZeroBased(
              rowIndex: rowLabelCell.rowIndex,
              columnIndex: entry.key,
            ),
            date: date,
            category: definition.category,
            period: definition.period,
            slot: definition.slot,
            workerName: worker,
            backgroundColor: workerCell?.backgroundColor?.hex,
          ),
        );
      }
    }

    if (assignments.isEmpty) {
      warnings.add('ไม่พบรายการเวรจากชีต ${input.sheetTitle}');
    }

    return RosterParseReport(
      assignments: assignments,
      warnings: warnings,
      periodStart: period.start,
      periodEnd: period.end,
    );
  }

  int _findDateHeaderRow(ShiftParserInput input) {
    for (final row in <int>[0, 1]) {
      final first = input.cells
          .where((cell) => cell.rowIndex == row && cell.columnIndex == 0)
          .map((cell) => cell.text?.trim())
          .whereType<String>()
          .firstOrNull;
      if (first == 'วันที่') return row;
    }
    throw const FormatException('ไม่พบแถวหัวข้อวันที่');
  }

  int? _asDay(Object? value) {
    if (value is num) {
      final day = value.toInt();
      return day >= 1 && day <= 31 ? day : null;
    }
    return int.tryParse(value?.toString().trim() ?? '');
  }

  DateTime _resolveDate({
    required int day,
    required DateTime start,
    required DateTime end,
  }) {
    final startMonthCandidate = DateTime(start.year, start.month, day);
    if (!startMonthCandidate.isBefore(start) &&
        !startMonthCandidate.isAfter(end)) {
      return startMonthCandidate;
    }
    final endMonthCandidate = DateTime(end.year, end.month, day);
    if (!endMonthCandidate.isBefore(start) && !endMonthCandidate.isAfter(end)) {
      return endMonthCandidate;
    }
    throw FormatException('วันที่ $day อยู่นอกช่วงตารางเวร');
  }

  _RowDefinition? _parseRowLabel(String value) {
    final text = value.trim().replaceAll(RegExp(r'\\s+'), ' ');
    final period = text.endsWith('เช้า')
        ? 'เช้า'
        : text.endsWith('บ่าย')
        ? 'บ่าย'
        : text.endsWith('ดึก')
        ? 'ดึก'
        : null;
    if (period == null) return null;

    final base = text.substring(0, text.length - period.length).trim();
    if (RegExp(r'^P[1-4]$', caseSensitive: false).hasMatch(base)) {
      return _RowDefinition(
        category: 'Portable',
        period: period,
        slot: base.toUpperCase(),
      );
    }

    final normalized = base
        .replaceAll('CT IPD', 'CT-IPD')
        .replaceAll('CT ER', 'CT-ER');
    const supported = <String>{'IPD', 'CT-IPD', 'CT-ER', 'ER', 'GEN', 'CT'};
    if (!supported.contains(normalized)) return null;
    return _RowDefinition(
      category: normalized,
      period: period,
      slot: normalized,
    );
  }
}

class _RowDefinition {
  const _RowDefinition({
    required this.category,
    required this.period,
    required this.slot,
  });
  final String category;
  final String period;
  final String slot;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
