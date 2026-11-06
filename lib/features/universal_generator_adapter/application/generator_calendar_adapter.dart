import '../../diff_engine/domain/calendar_event_candidate.dart';
import '../domain/generator_adapter_preview.dart';
import '../domain/generator_event_record.dart';

/// Converts reviewed Universal Generator records into Calendar preview data.
///
/// This adapter is intentionally preview-only: it has no Calendar gateway,
/// repository, file-system access, persistence or sync executor dependency.
class GeneratorCalendarAdapter {
  const GeneratorCalendarAdapter();

  GeneratorAdapterPreview preview(GeneratorEventBatch batch) {
    final issues = <GeneratorAdapterIssue>[];
    final candidates = <CalendarEventCandidate>[];
    final batchId = batch.batchId.trim();

    if (batchId.isEmpty) {
      issues.add(
        const GeneratorAdapterIssue(
          code: 'BATCH_ID_REQUIRED',
          message: 'Generator batch ID is required.',
          severity: GeneratorAdapterIssueSeverity.blocking,
        ),
      );
      return GeneratorAdapterPreview(candidates: candidates, issues: issues);
    }

    final seenIds = <String>{};
    for (final record in batch.records) {
      final recordId = record.sourceRecordId.trim();
      if (recordId.isEmpty) {
        issues.add(
          const GeneratorAdapterIssue(
            code: 'SOURCE_RECORD_ID_REQUIRED',
            message: 'Every source record must have an explicit stable ID.',
            severity: GeneratorAdapterIssueSeverity.blocking,
          ),
        );
        continue;
      }
      if (!seenIds.add(recordId)) {
        issues.add(
          GeneratorAdapterIssue(
            code: 'DUPLICATE_SOURCE_RECORD_ID',
            message: 'Duplicate source record ID: $recordId',
            severity: GeneratorAdapterIssueSeverity.blocking,
            sourceRecordId: recordId,
          ),
        );
        continue;
      }

      final title = record.title.trim();
      if (title.isEmpty) {
        issues.add(
          GeneratorAdapterIssue(
            code: 'EVENT_TITLE_REQUIRED',
            message: 'Event title is missing.',
            severity: GeneratorAdapterIssueSeverity.blocking,
            sourceRecordId: recordId,
          ),
        );
        continue;
      }

      final start = DateTime.tryParse(record.startIso8601);
      final end = DateTime.tryParse(record.endIso8601);
      if (start == null || end == null) {
        issues.add(
          GeneratorAdapterIssue(
            code: 'INVALID_EVENT_DATETIME',
            message: 'Start and end must be valid ISO-8601 date-times.',
            severity: GeneratorAdapterIssueSeverity.blocking,
            sourceRecordId: recordId,
          ),
        );
        continue;
      }
      if (!end.isAfter(start)) {
        issues.add(
          GeneratorAdapterIssue(
            code: 'INVALID_EVENT_RANGE',
            message: 'Event end must be later than event start.',
            severity: GeneratorAdapterIssueSeverity.blocking,
            sourceRecordId: recordId,
          ),
        );
        continue;
      }

      candidates.add(
        CalendarEventCandidate(
          syncId: 'universal-generator:$batchId:$recordId',
          title: title,
          start: start,
          end: end,
          shouldExist: true,
          description: record.description,
        ),
      );
    }

    return GeneratorAdapterPreview(candidates: candidates, issues: issues);
  }
}
