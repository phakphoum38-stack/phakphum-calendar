import '../domain/roster_analysis_models.dart';

/// Deterministic AI-style analyzer for roster tables.
///
/// The goal is to make the app understand many table shapes before a remote
/// LLM is added. It reads normalized frames produced by Excel, Google Sheets,
/// Calendar, pasted tables, or manual tables and converts them into canonical
/// daily roster plans.
class AiRosterAnalyzer {
  const AiRosterAnalyzer({this.clock});

  final DateTime Function()? clock;

  RosterAnalysisResult analyzeFrames(Iterable<RosterInputFrame> frames) {
    final records = <RosterAnalysisRecord>[];
    final warnings = <String>[];

    for (final frame in frames) {
      final profile = _detectColumns(frame.columns);
      if (!profile.hasDate) {
        warnings.add('ไม่พบคอลัมน์วันที่ใน ${frame.source.name}');
      }
      if (!profile.hasPerson) {
        warnings.add('ไม่พบคอลัมน์ชื่อคนใน ${frame.source.name}');
      }

      for (final row in frame.rows) {
        final record = _analyzeRow(frame, profile, row);
        if (record == null) continue;
        records.add(record);
      }
    }

    final dailyPlans = _buildDailyPlans(records);
    return RosterAnalysisResult(
      records: List.unmodifiable(records),
      dailyPlans: List.unmodifiable(dailyPlans),
      warnings: List.unmodifiable(warnings),
    );
  }

  _DetectedRosterColumns _detectColumns(List<String> columns) {
    String? date;
    String? person;
    String? role;
    String? site;
    String? note;
    String? relatedPerson;

    for (final column in columns) {
      final normalized = _normalize(column);
      if (date == null && _containsAny(normalized, const [
        'date',
        'day',
        'วันที่',
        'วัน',
        'เวรวันที่',
      ])) {
        date = column;
        continue;
      }
      if (person == null && _containsAny(normalized, const [
        'name',
        'person',
        'staff',
        'employee',
        'ชื่อ',
        'คนอยู่เวร',
        'ผู้ปฏิบัติงาน',
        'บุคลากร',
      ])) {
        person = column;
        continue;
      }
      if (role == null && _containsAny(normalized, const [
        'shift',
        'duty',
        'role',
        'ward',
        'เวร',
        'หน้าที่',
        'ตำแหน่ง',
        'แผนก',
      ])) {
        role = column;
        continue;
      }
      if (site == null && _containsAny(normalized, const [
        'site',
        'location',
        'station',
        'ward',
        'จุด',
        'ไซต์',
        'แอดไซต์',
        'สถานที่',
      ])) {
        site = column;
        continue;
      }
      if (relatedPerson == null && _containsAny(normalized, const [
        'แทน',
        'รับต่อ',
        'แลก',
        'ผู้แทน',
        'replace',
        'replacement',
        'exchange',
      ])) {
        relatedPerson = column;
        continue;
      }
      if (note == null && _containsAny(normalized, const [
        'note',
        'remark',
        'comment',
        'หมายเหตุ',
        'บันทึก',
      ])) {
        note = column;
      }
    }

    return _DetectedRosterColumns(
      date: date,
      person: person,
      role: role,
      site: site,
      note: note,
      relatedPerson: relatedPerson,
    );
  }

  RosterAnalysisRecord? _analyzeRow(
    RosterInputFrame frame,
    _DetectedRosterColumns profile,
    Map<String, String> row,
  ) {
    final rawText = row.values.where((value) => value.trim().isNotEmpty).join(' ');
    if (rawText.trim().isEmpty) return null;

    final date = _parseDate(row[profile.date] ?? rawText);
    if (date == null) {
      return RosterAnalysisRecord(
        date: _today(),
        kind: RosterDutyKind.unknown,
        source: frame.source,
        rawText: rawText,
        personName: _clean(row[profile.person]),
        roleLabel: _clean(row[profile.role]),
        siteLabel: _clean(row[profile.site]),
        relatedPersonName: _clean(row[profile.relatedPerson]),
        confidence: 0.2,
        notes: const ['อ่านแถวได้ แต่ยังตีความวันที่ไม่ได้'],
        rawCells: Map.unmodifiable(row),
      );
    }

    final kind = _classifyDutyKind(rawText);
    final confidence = _confidenceFor(kind, profile, row);
    return RosterAnalysisRecord(
      date: date,
      kind: kind,
      source: frame.source,
      rawText: rawText,
      personName: _clean(row[profile.person]) ?? _guessPersonName(row),
      roleLabel: _clean(row[profile.role]) ?? _guessRole(rawText),
      siteLabel: _clean(row[profile.site]) ?? _guessSite(rawText),
      relatedPersonName: _clean(row[profile.relatedPerson]),
      confidence: confidence,
      notes: _notesFor(kind, rawText),
      rawCells: Map.unmodifiable(row),
    );
  }

  RosterDutyKind _classifyDutyKind(String text) {
    final value = _normalize(text);

    if (_containsAny(value, const ['ลาป่วย', 'ลากิจ', 'ลาพัก', 'leave', 'vacation'])) {
      return RosterDutyKind.leave;
    }
    if (_containsAny(value, const ['ขาด', 'ไม่มา', 'absent', 'missing', 'no show', 'noshow'])) {
      return RosterDutyKind.absent;
    }
    if (_containsAny(value, const ['off', 'ออฟ', 'หยุด', 'พักเวร', 'พัก'])) {
      return RosterDutyKind.offDuty;
    }
    if (_containsAny(value, const ['รับเวร', 'รับต่อ', 'รับแทน', 'received', 'take over'])) {
      return RosterDutyKind.receivedExchange;
    }
    if (_containsAny(value, const ['แลกเวร', 'ให้เวร', 'ส่งเวร', 'given', 'swap out'])) {
      return RosterDutyKind.givenExchange;
    }
    if (_containsAny(value, const ['แทน', 'คนแทน', 'replacement', 'replace'])) {
      return RosterDutyKind.replacement;
    }
    if (_containsAny(value, const ['เสริม', 'คนเสริม', 'extra', 'backup', 'support'])) {
      return RosterDutyKind.extraStaff;
    }
    if (_containsAny(value, const ['แอดไซต์', 'add site', 'add-site', 'onsite', 'site'])) {
      return RosterDutyKind.onsite;
    }
    if (_containsAny(value, const ['ประจำ', 'regular', 'default', 'owner'])) {
      return RosterDutyKind.regularStaff;
    }
    if (_containsAny(value, const [
      'เวร',
      'เช้า',
      'บ่าย',
      'ดึก',
      'er',
      'ct',
      'ipd',
      'ward',
      'shift',
      'duty',
    ])) {
      return RosterDutyKind.primaryDuty;
    }
    return RosterDutyKind.unknown;
  }

  List<DailyRosterPlan> _buildDailyPlans(List<RosterAnalysisRecord> records) {
    final grouped = <DateTime, List<RosterAnalysisRecord>>{};
    for (final record in records) {
      final date = DateTime(record.date.year, record.date.month, record.date.day);
      grouped.putIfAbsent(date, () => <RosterAnalysisRecord>[]).add(record);
    }

    final dates = grouped.keys.toList()..sort();
    return [
      for (final date in dates)
        DailyRosterPlan(
          date: date,
          records: List.unmodifiable(grouped[date]!..sort(_recordSort)),
          warnings: List.unmodifiable(_dailyWarnings(date, grouped[date]!)),
        ),
    ];
  }

  List<String> _dailyWarnings(DateTime date, List<RosterAnalysisRecord> records) {
    final warnings = <String>[];
    final unavailable = records
        .where((record) => record.personName != null)
        .where((record) =>
            record.kind == RosterDutyKind.offDuty ||
            record.kind == RosterDutyKind.leave ||
            record.kind == RosterDutyKind.absent)
        .map((record) => record.personName!.trim())
        .toSet();

    final assignedUnavailable = records.where((record) {
      final name = record.personName?.trim();
      if (name == null || name.isEmpty) return false;
      return unavailable.contains(name) &&
          (record.kind == RosterDutyKind.primaryDuty ||
              record.kind == RosterDutyKind.regularStaff ||
              record.kind == RosterDutyKind.replacement ||
              record.kind == RosterDutyKind.extraStaff ||
              record.kind == RosterDutyKind.onsite);
    }).toList();

    if (assignedUnavailable.isNotEmpty) {
      warnings.add(
        'วันที่ ${date.day}/${date.month}/${date.year} มีคนถูกจัดเวรทั้งที่ถูกระบุว่าออฟ/ลา/ขาด',
      );
    }

    final unknownCount = records.where((record) => record.kind == RosterDutyKind.unknown).length;
    if (unknownCount > 0) {
      warnings.add('มี $unknownCount รายการที่ AI Analyzer ยังไม่มั่นใจในการจำแนก');
    }

    return warnings;
  }

  int _recordSort(RosterAnalysisRecord a, RosterAnalysisRecord b) {
    final site = (a.siteLabel ?? '').compareTo(b.siteLabel ?? '');
    if (site != 0) return site;
    final role = (a.roleLabel ?? '').compareTo(b.roleLabel ?? '');
    if (role != 0) return role;
    return (a.personName ?? '').compareTo(b.personName ?? '');
  }

  double _confidenceFor(
    RosterDutyKind kind,
    _DetectedRosterColumns profile,
    Map<String, String> row,
  ) {
    var score = kind == RosterDutyKind.unknown ? 0.3 : 0.65;
    if (_clean(row[profile.date]) != null) score += 0.1;
    if (_clean(row[profile.person]) != null) score += 0.1;
    if (_clean(row[profile.role]) != null) score += 0.1;
    if (_clean(row[profile.site]) != null) score += 0.05;
    return score.clamp(0.0, 0.95);
  }

  List<String> _notesFor(RosterDutyKind kind, String rawText) {
    if (kind != RosterDutyKind.unknown) return const [];
    return ['ต้องตรวจสอบคำในแถวนี้เพิ่มเติม: $rawText'];
  }

  DateTime? _parseDate(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    final iso = DateTime.tryParse(value);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);

    final match = RegExp(r'(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?').firstMatch(value);
    if (match == null) return null;

    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final rawYear = match.group(3);
    if (day == null || month == null) return null;

    final now = _today();
    var year = rawYear == null ? now.year : int.tryParse(rawYear) ?? now.year;
    if (year < 100) year += 2000;
    if (year > 2400) year -= 543;

    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String? _guessPersonName(Map<String, String> row) {
    for (final value in row.values) {
      final cleaned = _clean(value);
      if (cleaned == null) continue;
      if (RegExp(r'^[ก-๙a-zA-Z .]{2,60}$').hasMatch(cleaned) &&
          !_containsAny(_normalize(cleaned), const ['เวร', 'เช้า', 'บ่าย', 'ดึก', 'off'])) {
        return cleaned;
      }
    }
    return null;
  }

  String? _guessRole(String rawText) {
    final match = RegExp(r'(ER|CT|IPD|P\d|U\d+|เช้า|บ่าย|ดึก|เวร[^ ]*)', caseSensitive: false)
        .firstMatch(rawText);
    return match?.group(0);
  }

  String? _guessSite(String rawText) {
    final match = RegExp(r'(ER|CT|IPD|U\d+|ชั้น\s*\d+|ไซต์[^ ]*)', caseSensitive: false)
        .firstMatch(rawText);
    return match?.group(0);
  }

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '-') return null;
    return trimmed;
  }

  DateTime _today() {
    final now = (clock ?? DateTime.now)();
    return DateTime(now.year, now.month, now.day);
  }

  bool _containsAny(String value, List<String> tokens) {
    return tokens.any((token) => value.contains(_normalize(token)));
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _DetectedRosterColumns {
  const _DetectedRosterColumns({
    this.date,
    this.person,
    this.role,
    this.site,
    this.note,
    this.relatedPerson,
  });

  final String? date;
  final String? person;
  final String? role;
  final String? site;
  final String? note;
  final String? relatedPerson;

  bool get hasDate => date != null;
  bool get hasPerson => person != null;
}
