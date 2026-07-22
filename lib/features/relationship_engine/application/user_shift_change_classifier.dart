import '../domain/user_shift_change.dart';
import 'roster_comparison_engine.dart';

class UserShiftChangeClassifier {
  const UserShiftChangeClassifier();

  List<UserShiftChange> classify({
    required List<RosterAssignmentChange> changes,
    required Iterable<String> userAliases,
  }) {
    final aliases = userAliases.map(_normalize).toSet();
    return changes
        .map((change) {
          final wasUser =
              change.original != null &&
              aliases.contains(_normalize(change.original!.workerName));
          final isUser =
              change.current != null &&
              aliases.contains(_normalize(change.current!.workerName));

          final type = wasUser && isUser
              ? UserShiftChangeType.ownUnchanged
              : !wasUser && isUser
              ? UserShiftChangeType.received
              : wasUser && !isUser
              ? UserShiftChangeType.givenAway
              : UserShiftChangeType.unrelated;
          return UserShiftChange(
            type: type,
            positionKey: change.positionKey,
            before: change.original,
            after: change.current,
          );
        })
        .where((item) => item.type != UserShiftChangeType.unrelated)
        .toList(growable: false);
  }

  String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\\s+'), ' ').toLowerCase();
}
