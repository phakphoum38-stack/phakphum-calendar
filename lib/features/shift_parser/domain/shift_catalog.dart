import 'shift_definition.dart';

class ShiftCatalog {
  const ShiftCatalog(this.definitions);

  final List<ShiftDefinition> definitions;

  ShiftDefinition? find({required String category, required String period}) {
    final normalizedCategory = category.trim().toLowerCase();
    final normalizedPeriod = period.trim().toLowerCase();

    for (final definition in definitions) {
      if (definition.category.trim().toLowerCase() == normalizedCategory &&
          definition.period.trim().toLowerCase() == normalizedPeriod) {
        return definition;
      }
    }

    return null;
  }

  static const known = ShiftCatalog([
    ShiftDefinition(
      category: 'Portable',
      period: 'เช้า',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'Portable',
      period: 'บ่าย',
      startHour: 16,
      startMinute: 0,
      endHour: 0,
      endMinute: 0,
      endsNextDay: true,
    ),
    ShiftDefinition(
      category: 'Portable',
      period: 'ดึก',
      startHour: 0,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'IPD',
      period: 'เช้า',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'IPD',
      period: 'บ่าย',
      startHour: 16,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: true,
    ),
    ShiftDefinition(
      category: 'CT-IPD',
      period: 'เช้า',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'CT-IPD',
      period: 'บ่าย',
      startHour: 16,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: true,
    ),
    ShiftDefinition(
      category: 'CT-ER',
      period: 'เช้า',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'CT-ER',
      period: 'บ่าย',
      startHour: 16,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: true,
    ),
    ShiftDefinition(
      category: 'ER',
      period: 'เช้า',
      startHour: 8,
      startMinute: 0,
      endHour: 16,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'ER',
      period: 'บ่าย',
      startHour: 16,
      startMinute: 0,
      endHour: 0,
      endMinute: 0,
      endsNextDay: true,
    ),
    ShiftDefinition(
      category: 'ER',
      period: 'ดึก',
      startHour: 0,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'GEN',
      period: 'เช้า',
      startHour: 7,
      startMinute: 30,
      endHour: 12,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: 'GEN',
      period: 'บ่าย',
      startHour: 16,
      startMinute: 30,
      endHour: 20,
      endMinute: 0,
      endsNextDay: false,
    ),
    ShiftDefinition(
      category: '14 ชั้น',
      period: 'เช้า',
      startHour: 7,
      startMinute: 0,
      endHour: 8,
      endMinute: 0,
      endsNextDay: false,
    ),
  ]);
}
