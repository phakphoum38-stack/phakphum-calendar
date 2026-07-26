import '../../diff_engine/domain/calendar_event_candidate.dart';

enum CalendarSyncAction { create, update, delete, skip }

class CalendarSyncCommand {
  const CalendarSyncCommand._({
    required this.action,
    required this.candidate,
    this.providerEventId,
    this.reason,
  });

  factory CalendarSyncCommand.create({
    required CalendarEventCandidate candidate,
    String? reason,
  }) {
    return CalendarSyncCommand._(
      action: CalendarSyncAction.create,
      candidate: candidate,
      reason: reason,
    );
  }

  factory CalendarSyncCommand.update({
    required String providerEventId,
    required CalendarEventCandidate candidate,
    String? reason,
  }) {
    return CalendarSyncCommand._(
      action: CalendarSyncAction.update,
      providerEventId: _requireProviderEventId(providerEventId),
      candidate: candidate,
      reason: reason,
    );
  }

  factory CalendarSyncCommand.delete({
    required String providerEventId,
    required CalendarEventCandidate candidate,
    String? reason,
  }) {
    return CalendarSyncCommand._(
      action: CalendarSyncAction.delete,
      providerEventId: _requireProviderEventId(providerEventId),
      candidate: candidate,
      reason: reason,
    );
  }

  factory CalendarSyncCommand.skip({
    required CalendarEventCandidate candidate,
    String? providerEventId,
    String? reason,
  }) {
    return CalendarSyncCommand._(
      action: CalendarSyncAction.skip,
      providerEventId: _normalizeOptional(providerEventId),
      candidate: candidate,
      reason: reason,
    );
  }

  final CalendarSyncAction action;
  final CalendarEventCandidate candidate;
  final String? providerEventId;
  final String? reason;

  static String _requireProviderEventId(String value) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'providerEventId',
        'Provider event ID must not be empty.',
      );
    }

    return normalized;
  }

  static String? _normalizeOptional(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
