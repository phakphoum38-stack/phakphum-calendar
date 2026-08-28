import 'package:http/http.dart' as http;

import '../models/roster_assignment_timeline.dart';
import '../services/roster_revision_service.dart';
import 'shift_parser.dart';

/// Lightweight generator that produces `RosterAssignmentTimeline` maps from a
/// sequence of roster revision documents or from a Drive file on-demand.
class RosterTimelineGenerator {
  const RosterTimelineGenerator();

  /// Build timelines from already-downloaded revision documents (in memory).
  Map<String, RosterAssignmentTimeline> generateFromDocuments(
    Iterable<RosterRevisionDocument> documents,
  ) {
    final revisions = <RosterRevisionShifts>[];
    for (final doc in documents) {
      // parse snapshots into shifts for this revision
      final shifts = ShiftParser().parseAllWorkersAllPeriods(snapshots: doc.snapshots);
      revisions.add(RosterRevisionShifts(
        revisionId: doc.revisionId,
        modifiedAt: doc.modifiedAt,
        shifts: shifts,
      ));
    }
    return buildRosterAssignmentTimelines(revisions);
  }

  /// Read revision exports transiently (no long-lived cache) and build
  /// timelines. This contacts Drive and returns timelines without persisting
  /// revision snapshots anywhere long-term.
  Future<Map<String, RosterAssignmentTimeline>> generateFromDrive(
    http.Client client,
    String fileId, {
    RosterRevisionService service = const RosterRevisionService(),
  }) async {
    final docs = await service.readHistoryTransient(client, fileId);
    return generateFromDocuments(docs);
  }
}
