import '../domain/roster_file.dart';

enum RosterFileSlot { original, current }

class RosterSelectionState {
  const RosterSelectionState({this.original, this.current});

  final RosterFile? original;
  final RosterFile? current;

  bool get canCompare =>
      original != null && current != null && original!.id != current!.id;

  RosterSelectionState copyWith({
    RosterFile? original,
    RosterFile? current,
    bool clearOriginal = false,
    bool clearCurrent = false,
  }) {
    return RosterSelectionState(
      original: clearOriginal ? null : (original ?? this.original),
      current: clearCurrent ? null : (current ?? this.current),
    );
  }
}
