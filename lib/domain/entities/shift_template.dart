import 'shift_type.dart';

/// Configurable definition used to create canonical shift assignments.
class ShiftTemplate {
  const ShiftTemplate({
    required this.id,
    required this.code,
    required this.name,
    required this.shortName,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.workingHours,
    this.description = '',
    this.location,
    this.defaultCalendarId,
    this.reminderMinutes,
    this.rate = 0,
    this.active = true,
    this.sortOrder = 0,
  }) : assert(workingHours >= 0),
       assert(rate >= 0),
       assert(sortOrder >= 0);

  final String id;
  final String code;
  final String name;
  final String shortName;
  final String description;
  final Duration startTime;
  final Duration endTime;
  final int color;
  final double workingHours;
  final String? location;
  final String? defaultCalendarId;
  final int? reminderMinutes;
  final double rate;
  final bool active;
  final int sortOrder;

  bool get overnight => endTime <= startTime;

  /// Creates the canonical shift type placed in a schedule assignment.
  ShiftType toShiftType() {
    return ShiftType(
      id: id,
      code: code,
      name: name,
      color: color,
      startTime: startTime,
      endTime: endTime,
      workingHours: workingHours,
    );
  }

  /// Creates an updated immutable template.
  ShiftTemplate copyWith({
    String? id,
    String? code,
    String? name,
    String? shortName,
    String? description,
    Duration? startTime,
    Duration? endTime,
    int? color,
    double? workingHours,
    String? location,
    String? defaultCalendarId,
    int? reminderMinutes,
    double? rate,
    bool? active,
    int? sortOrder,
  }) {
    return ShiftTemplate(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      workingHours: workingHours ?? this.workingHours,
      location: location ?? this.location,
      defaultCalendarId: defaultCalendarId ?? this.defaultCalendarId,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      rate: rate ?? this.rate,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
