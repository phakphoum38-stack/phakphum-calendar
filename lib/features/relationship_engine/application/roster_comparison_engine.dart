import '../../shift_parser/domain/roster_cell_assignment.dart';

class RosterAssignmentChange {
  const RosterAssignmentChange({
    required this.positionKey,
    required this.original,
    required this.current,
    required this.type,
  });

  final String positionKey;
  final RosterCellAssignment? original;
  final RosterCellAssignment? current;
  final RosterAssignmentChangeType type;
}

enum RosterAssignmentChangeType {
  added,
  removed,
  reassigned,
  unchanged,
}

class RosterComparisonEngine {
  const RosterComparisonEngine();

  List<RosterAssignmentChange> compare({
    required List<RosterCellAssignment> original,
    required List<RosterCellAssignment> current,
  }) {
    final originalByKey = {
      for (final item in original) item.positionKey: item,
    };
    final currentByKey = {
      for (final item in current) item.positionKey: item,
    };
    final keys = <String>{
      ...originalByKey.keys,
      ...currentByKey.keys,
    }.toList()..sort();

    return keys.map((key) {
      final before = originalByKey[key];
      final after = currentByKey[key];
      final type = before == null
          ? RosterAssignmentChangeType.added
          : after == null
              ? RosterAssignmentChangeType.removed
              : _normalize(before.workerName) == _normalize(after.workerName)
                  ? RosterAssignmentChangeType.unchanged
                  : RosterAssignmentChangeType.reassigned;
      return RosterAssignmentChange(
        positionKey: key,
        original: before,
        current: after,
        type: type,
      );
    }).toList(growable: false);
  }

  List<RosterAssignmentChange> changesForUser({
    required List<RosterAssignmentChange> changes,
    required Iterable<String> aliases,
  }) {
    final names = aliases.map(_normalize).toSet();
    return changes.where((change) {
      final before = change.original?.workerName;
      final after = change.current?.workerName;
      return (before != null && names.contains(_normalize(before))) ||
          (after != null && names.contains(_normalize(after)));
    }).toList(growable: false);
  }

  String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\\s+'), ' ').toLowerCase();
}
