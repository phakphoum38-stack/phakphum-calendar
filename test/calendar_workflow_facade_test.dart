import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/features/diff_engine/domain/calendar_event_candidate.dart';
import 'package:phakphum_calendar/features/workflow/application/workflow_preview_builder.dart';
import 'package:phakphum_calendar/models/shift.dart';
import 'package:phakphum_calendar/services/calendar_service.dart';

void main() {
  test('candidate preview does not delete unrelated managed events', () {
    final desired = _event('wanted');
    final unrelated = _event('unrelated');

    final preview = const WorkflowPreviewBuilder().buildCandidates(
      desired: [desired],
      existing: [unrelated],
    );

    expect(preview.diff.toAdd, [desired]);
    expect(preview.diff.toDelete, isEmpty);
  });

  test('candidate content comparison includes calendar color', () {
    final blue = _event('wanted', colorId: '7');
    final red = _event('wanted', colorId: '11');

    expect(blue.contentEquals(red), isFalse);
  });

  test('legacy shift metadata remains stable for workflow migration', () {
    final shift = Shift(
      code: 'UP1',
      rowLabel: 'P1 เช้า',
      assignedName: 'ภาคภูมิ',
      start: DateTime(2026, 8, 3, 8),
      end: DateTime(2026, 8, 3, 16),
      sheetTitle: 'ส.ค. 69',
      cell: 'D5',
      category: ShiftCategory.own,
    );

    expect(CalendarService.keyFor(shift), hasLength(32));
    expect(CalendarService.summaryFor(shift), 'P1 เช้า (UP1)');
    expect(
      CalendarService.descriptionFor(shift),
      contains('ชีต: ส.ค. 69 เซลล์ D5'),
    );
  });
}

CalendarEventCandidate _event(String syncId, {String? colorId}) {
  return CalendarEventCandidate(
    syncId: syncId,
    title: syncId,
    start: DateTime(2026, 8, 3, 8),
    end: DateTime(2026, 8, 3, 16),
    colorId: colorId,
    shouldExist: true,
  );
}
