import '../../../domain/entities/shift_type.dart';
import 'staff_group.dart';

enum DutyPeriod { morning, afternoon, night }

class RosterDutySlot {
  const RosterDutySlot({
    required this.id,
    required this.label,
    required this.location,
    required this.period,
    required this.shiftTypeId,
    required this.allowedGroups,
  });

  final String id;
  final String label;
  final String location;
  final DutyPeriod period;
  final String shiftTypeId;
  final Set<StaffGroup> allowedGroups;
}

class MonthlyRosterBlueprint {
  const MonthlyRosterBlueprint({required this.shiftTypes, required this.slots});

  final List<ShiftType> shiftTypes;
  final List<RosterDutySlot> slots;
}
