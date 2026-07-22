import '../../shift_parser/domain/roster_cell_assignment.dart';

enum UserShiftChangeType {
  ownUnchanged,
  received,
  givenAway,
  movedBetweenSlots,
  unrelated,
}

class UserShiftChange {
  const UserShiftChange({
    required this.type,
    required this.positionKey,
    this.before,
    this.after,
  });

  final UserShiftChangeType type;
  final String positionKey;
  final RosterCellAssignment? before;
  final RosterCellAssignment? after;
}
