enum ShiftCategory {
  own,
  other,
  clinic,
  off,
  majorSwap,
  given,
  borrowedUnpaid,
  borrowedPaid,
}

extension ShiftCategoryInfo on ShiftCategory {
  String get label => switch (this) {
    ShiftCategory.own => 'เวรของตัวเอง',
    ShiftCategory.other => 'เวรคนอื่น',
    ShiftCategory.clinic => 'เวรคลินิก',
    ShiftCategory.off => 'เวรออฟหลังเวรดึก',
    ShiftCategory.majorSwap => 'แลกเวรใหญ่',
    ShiftCategory.given => 'ยกเวร',
    ShiftCategory.borrowedUnpaid => 'ยืมชื่อเวร (ไม่จ่าย)',
    ShiftCategory.borrowedPaid => 'ยืมชื่อเวร (จ่าย)',
  };

  String get colorName => switch (this) {
    ShiftCategory.own => 'กราไฟต์',
    ShiftCategory.other => 'มะเขือเทศ',
    ShiftCategory.clinic => 'ฟ้า',
    ShiftCategory.off => 'ลาเวนเดอร์',
    ShiftCategory.majorSwap => 'องุ่น',
    ShiftCategory.given => 'ลาเวนเดอร์',
    ShiftCategory.borrowedUnpaid => 'กล้วย',
    ShiftCategory.borrowedPaid => 'เขียว',
  };

  String get googleColorId => switch (this) {
    ShiftCategory.own => '8',
    ShiftCategory.other => '11',
    ShiftCategory.clinic => '9',
    ShiftCategory.off => '3',
    ShiftCategory.majorSwap => '3',
    ShiftCategory.given => '1',
    ShiftCategory.borrowedUnpaid => '5',
    ShiftCategory.borrowedPaid => '10',
  };

  int get colorValue => switch (this) {
    ShiftCategory.own => 0xFF616161,
    ShiftCategory.other => 0xFFD50000,
    ShiftCategory.clinic => 0xFF039BE5,
    ShiftCategory.off => 0xFF7986CB,
    ShiftCategory.majorSwap => 0xFF7986CB,
    ShiftCategory.given => 0xFFA4BDFC,
    ShiftCategory.borrowedUnpaid => 0xFFF6BF26,
    ShiftCategory.borrowedPaid => 0xFF0B8043,
  };
}

class Shift {
  const Shift({
    required this.code,
    required this.rowLabel,
    required this.assignedName,
    required this.start,
    required this.end,
    required this.sheetTitle,
    required this.cell,
    required this.category,
    this.excluded = false,
    this.generated = false,
    this.linkedShiftKey,
  });

  final String code;
  final String rowLabel;
  final String assignedName;
  final DateTime start;
  final DateTime end;
  final String sheetTitle;
  final String cell;
  final ShiftCategory category;
  final bool excluded;
  final bool generated;
  final String? linkedShiftKey;

  bool get isNightShift =>
      code.startsWith('N') && start.hour == 0 && end.hour == 8;
  bool get isOffDuty => category == ShiftCategory.off || code == 'OFF';

  String get sourceKey =>
      '${start.year.toString().padLeft(4, '0')}-'
      '${start.month.toString().padLeft(2, '0')}-'
      '${start.day.toString().padLeft(2, '0')}|$code|$assignedName';

  Shift copyWith({ShiftCategory? category, bool? excluded}) => Shift(
    code: code,
    rowLabel: rowLabel,
    assignedName: assignedName,
    start: start,
    end: end,
    sheetTitle: sheetTitle,
    cell: cell,
    category: category ?? this.category,
    excluded: excluded ?? this.excluded,
    generated: generated,
    linkedShiftKey: linkedShiftKey,
  );
}

class SheetSnapshot {
  const SheetSnapshot({required this.title, required this.rows});

  final String title;
  final List<List<Object?>> rows;
}
