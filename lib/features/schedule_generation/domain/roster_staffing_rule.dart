import 'staff_group.dart';

class RosterStaffingRule {
  const RosterStaffingRule({
    required this.slotId,
    required this.staffGroup,
    required this.requiredEmployees,
    this.weekdays = const {1, 2, 3, 4, 5, 6, 7},
  }) : assert(requiredEmployees >= 0);

  final String slotId;
  final StaffGroup staffGroup;
  final int requiredEmployees;
  final Set<int> weekdays;
}
