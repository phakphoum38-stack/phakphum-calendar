import '../../calendar_engine/domain/sync_id_factory.dart';
import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../../relationship_engine/domain/user_shift_change.dart';
import '../../shift_parser/domain/roster_cell_assignment.dart';
import '../../shift_parser/domain/shift_catalog.dart';

class UserShiftEventMappingResult {
  const UserShiftEventMappingResult({
    required this.candidates,
    required this.warnings,
    required this.blockedCount,
  });

  final List<CalendarEventCandidate> candidates;
  final List<String> warnings;
  final int blockedCount;
}

class UserShiftEventMapper {
  const UserShiftEventMapper({
    this.catalog = ShiftCatalog.known,
    this.syncIdFactory = const SyncIdFactory(),
  });

  final ShiftCatalog catalog;
  final SyncIdFactory syncIdFactory;

  UserShiftEventMappingResult mapChanges(List<UserShiftChange> changes) {
    final candidates = <CalendarEventCandidate>[];
    final warnings = <String>[];
    var blockedCount = 0;

    for (final change in changes) {
      if (change.type == UserShiftChangeType.unrelated) {
        continue;
      }

      final assignment = change.after ?? change.before;
      if (assignment == null) {
        warnings.add('ไม่พบข้อมูลเวรสำหรับ ${change.positionKey}');
        blockedCount++;
        continue;
      }

      final definition = catalog.find(
        category: assignment.category,
        period: assignment.period,
      );

      if (definition == null) {
        warnings.add(
          'ยังไม่มีเวลาที่กำหนดสำหรับ '
          '${assignment.category} ${assignment.period} '
          '(${assignment.sourceCell})',
        );
        blockedCount++;
        continue;
      }

      final shouldExist = switch (change.type) {
        UserShiftChangeType.ownUnchanged => true,
        UserShiftChangeType.received => true,
        UserShiftChangeType.givenAway => false,
        UserShiftChangeType.movedBetweenSlots => true,
        UserShiftChangeType.unrelated => false,
      };

      final syncSource = change.before ?? assignment;
      final syncId = syncIdFactory.create(
        spreadsheetId: syncSource.spreadsheetId,
        sheetId: syncSource.sheetId,
        cellA1: syncSource.sourceCell,
        date: syncSource.date,
        category: syncSource.category,
        period: syncSource.period,
      );

      candidates.add(
        CalendarEventCandidate(
          syncId: syncId,
          title: _titleFor(assignment),
          start: definition.startFor(assignment.date),
          end: definition.endFor(assignment.date),
          shouldExist: shouldExist,
          description: _descriptionFor(change, assignment),
        ),
      );
    }

    return UserShiftEventMappingResult(
      candidates: candidates,
      warnings: warnings,
      blockedCount: blockedCount,
    );
  }

  String _titleFor(RosterCellAssignment assignment) {
    final slot = assignment.slot.trim();
    final suffix = slot.isEmpty ? '' : ' $slot';
    return '${assignment.category} ${assignment.period}$suffix';
  }

  String _descriptionFor(
    UserShiftChange change,
    RosterCellAssignment assignment,
  ) {
    final relationship = switch (change.type) {
      UserShiftChangeType.ownUnchanged => 'เวรของผู้ใช้',
      UserShiftChangeType.received => 'รับเวรมา',
      UserShiftChangeType.givenAway => 'ยกเวรให้ผู้อื่น',
      UserShiftChangeType.movedBetweenSlots => 'ย้ายตำแหน่งเวร',
      UserShiftChangeType.unrelated => 'ไม่เกี่ยวข้องกับผู้ใช้',
    };

    return <String>[
      'จัดการโดย Shift Calendar Engine',
      'สถานะ: $relationship',
      'ชีต: ${assignment.sheetTitle}',
      'เซลล์ต้นทาง: ${assignment.sourceCell}',
    ].join('\n');
  }
}
