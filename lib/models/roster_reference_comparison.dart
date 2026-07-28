import 'shift.dart';

/// Read-only comparison between the roster selected for synchronization and
/// an optional original file attached from the local device.
class RosterReferenceComparison {
  const RosterReferenceComparison({
    required this.matched,
    required this.changed,
    required this.missingFromSync,
    required this.onlyInSync,
  });

  factory RosterReferenceComparison.compare({
    required Iterable<Shift> syncShifts,
    required Iterable<Shift> referenceShifts,
  }) {
    final syncByKey = <String, Shift>{
      for (final shift in syncShifts)
        if (!shift.generated) shift.sourceKey: shift,
    };
    final referenceByKey = <String, Shift>{
      for (final shift in referenceShifts)
        if (!shift.generated) shift.sourceKey: shift,
    };
    var matched = 0;
    var changed = 0;

    for (final entry in referenceByKey.entries) {
      final sync = syncByKey[entry.key];
      if (sync == null) continue;
      if (_sameContent(sync, entry.value)) {
        matched++;
      } else {
        changed++;
      }
    }

    return RosterReferenceComparison(
      matched: matched,
      changed: changed,
      missingFromSync: referenceByKey.keys
          .where((key) => !syncByKey.containsKey(key))
          .length,
      onlyInSync: syncByKey.keys
          .where((key) => !referenceByKey.containsKey(key))
          .length,
    );
  }

  final int matched;
  final int changed;
  final int missingFromSync;
  final int onlyInSync;

  int get issueCount => changed + missingFromSync + onlyInSync;
  bool get isExactMatch => issueCount == 0;

  static bool _sameContent(Shift left, Shift right) =>
      left.code.trim() == right.code.trim() &&
      left.assignedName.trim() == right.assignedName.trim() &&
      left.start == right.start &&
      left.end == right.end &&
      left.displayName.trim() == right.displayName.trim();
}
