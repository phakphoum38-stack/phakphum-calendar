import '../models/calendar_busy_period.dart';
import '../models/shift.dart';
import '../models/shift_alert.dart';
import 'calendar_service.dart';

class ShiftAlertService {
  const ShiftAlertService();

  List<Shift> addOffDutyPeriods(List<Shift> sourceShifts) {
    final result = <Shift>[...sourceShifts];
    final offByDate = <String>{
      for (final shift in sourceShifts.where((shift) => shift.isOffDuty))
        _dateKey(shift.start),
    };
    for (final night in sourceShifts.where(
      (shift) => shift.isNightShift && !shift.excluded,
    )) {
      final start = night.end;
      if (!offByDate.add(_dateKey(start))) continue;
      result.add(
        Shift(
          code: 'OFF',
          rowLabel: 'เวรออฟหลังเวรดึก',
          assignedName: night.assignedName,
          start: start,
          end: DateTime(start.year, start.month, start.day, 16),
          sheetTitle: night.sheetTitle,
          cell: night.cell,
          category: ShiftCategory.off,
          generated: true,
          linkedShiftKey: night.sourceKey,
        ),
      );
    }
    result.sort((left, right) {
      final byStart = left.start.compareTo(right.start);
      return byStart != 0 ? byStart : left.code.compareTo(right.code);
    });
    return result;
  }

  List<ShiftAlert> build({
    required List<Shift> shifts,
    required List<CalendarBusyPeriod> calendarPeriods,
    required Map<String, ShiftAlertDecision> decisions,
  }) {
    final activeShifts = shifts.where((shift) => !shift.excluded).toList();
    final alerts = <ShiftAlert>[];

    for (final off in activeShifts.where((shift) => shift.isOffDuty)) {
      final night = _findBySourceKey(activeShifts, off.linkedShiftKey);
      final id = 'off|${off.sourceKey}';
      alerts.add(
        ShiftAlert(
          id: id,
          type: ShiftAlertType.offAfterNight,
          title: 'สร้างเวรออฟหลังเวรดึกแล้ว',
          message:
              '${night?.displayName ?? 'เวรดึก'} สิ้นสุดเวลา 08:00 '
              'ระบบกำหนดช่วง 08:00–16:00 เป็น OFF อัตโนมัติ',
          start: off.start,
          end: off.end,
          decision: decisions[id] ?? ShiftAlertDecision.acknowledged,
          primaryShiftKey: night?.sourceKey,
          targetShiftKey: off.sourceKey,
          offShiftKey: off.sourceKey,
        ),
      );
    }

    for (var firstIndex = 0; firstIndex < activeShifts.length; firstIndex++) {
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < activeShifts.length;
        secondIndex++
      ) {
        final first = activeShifts[firstIndex];
        final second = activeShifts[secondIndex];
        if (!_overlaps(first.start, first.end, second.start, second.end)) {
          continue;
        }
        if (first.isOffDuty || second.isOffDuty) {
          final off = first.isOffDuty ? first : second;
          final duty = first.isOffDuty ? second : first;
          final id = 'off-conflict|${off.sourceKey}|${duty.sourceKey}';
          alerts.add(
            ShiftAlert(
              id: id,
              type: ShiftAlertType.offConflict,
              title: 'เวรชนช่วง OFF 08:00–16:00',
              message:
                  '${duty.displayName} ${_range(duty.start, duty.end)} ชนกับช่วง '
                  'OFF หลังเวรดึก ${_range(off.start, off.end)}',
              start: _later(duty.start, off.start),
              end: _earlier(duty.end, off.end),
              decision: decisions[id] ?? ShiftAlertDecision.pending,
              primaryShiftKey: off.linkedShiftKey,
              targetShiftKey: duty.sourceKey,
              offShiftKey: off.sourceKey,
            ),
          );
          continue;
        }
        final id = 'shift-overlap|${first.sourceKey}|${second.sourceKey}';
        alerts.add(
          ShiftAlert(
            id: id,
            type: ShiftAlertType.shiftOverlap,
            title: 'พบเวรซ้อนจากตารางเวร',
            message:
                '${first.displayName} ${_range(first.start, first.end)} ชนกับ '
                '${second.displayName} ${_range(second.start, second.end)}',
            start: _later(first.start, second.start),
            end: _earlier(first.end, second.end),
            decision: decisions[id] ?? ShiftAlertDecision.pending,
            primaryShiftKey: first.sourceKey,
            targetShiftKey: second.sourceKey,
          ),
        );
      }
    }

    for (final shift in activeShifts) {
      for (final period in calendarPeriods) {
        if (CalendarService.matchesLegacyEvent(shift, period.legacyKey) ||
            !_overlaps(shift.start, shift.end, period.start, period.end)) {
          continue;
        }
        final id =
            'calendar-overlap|${shift.sourceKey}|${period.id}|'
            '${period.start.toIso8601String()}';
        final offConflict = shift.isOffDuty;
        alerts.add(
          ShiftAlert(
            id: id,
            type: ShiftAlertType.calendarOverlap,
            title: offConflict
                ? 'กิจกรรมใน Calendar ชนช่วง OFF 08:00–16:00'
                : 'เวรชนกิจกรรมเดิมใน Calendar',
            message: offConflict
                ? 'ช่วง OFF หลังเวรดึก ${_range(shift.start, shift.end)} ชนกับ '
                      '“${period.title}” ${_range(period.start, period.end)}'
                : '${shift.displayName} ${_range(shift.start, shift.end)} ชนกับ '
                      '“${period.title}” ${_range(period.start, period.end)}',
            start: _later(shift.start, period.start),
            end: _earlier(shift.end, period.end),
            decision: decisions[id] ?? ShiftAlertDecision.pending,
            primaryShiftKey: shift.linkedShiftKey ?? shift.sourceKey,
            targetShiftKey: shift.sourceKey,
            offShiftKey: offConflict ? shift.sourceKey : null,
          ),
        );
      }
    }

    alerts.sort((left, right) {
      final byPending = (left.isPending ? 0 : 1).compareTo(
        right.isPending ? 0 : 1,
      );
      return byPending != 0 ? byPending : left.start.compareTo(right.start);
    });
    return alerts;
  }

  Shift? _findBySourceKey(List<Shift> shifts, String? sourceKey) {
    if (sourceKey == null) return null;
    for (final shift in shifts) {
      if (shift.sourceKey == sourceKey) return shift;
    }
    return null;
  }

  bool _overlaps(
    DateTime firstStart,
    DateTime firstEnd,
    DateTime secondStart,
    DateTime secondEnd,
  ) => firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);

  DateTime _later(DateTime first, DateTime second) =>
      first.isAfter(second) ? first : second;

  DateTime _earlier(DateTime first, DateTime second) =>
      first.isBefore(second) ? first : second;

  String _range(DateTime start, DateTime end) =>
      '${_date(start)} ${_time(start)}–${_time(end)}';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';
}
