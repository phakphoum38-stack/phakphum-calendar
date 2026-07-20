import '../models/calendar_busy_period.dart';
import '../models/shift.dart';
import '../models/shift_alert.dart';
import 'calendar_service.dart';

class ShiftAlertService {
  const ShiftAlertService();

  List<Shift> addOffDutyPeriods(List<Shift> sourceShifts) {
    final result = <Shift>[...sourceShifts];
    final offByDate = <String>{};
    for (final night in sourceShifts.where((shift) => shift.isNightShift)) {
      final start = night.end;
      final dateKey = '${start.year}-${start.month}-${start.day}';
      if (!offByDate.add(dateKey)) continue;
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
    result.sort((a, b) {
      final byStart = a.start.compareTo(b.start);
      return byStart != 0 ? byStart : a.code.compareTo(b.code);
    });
    return result;
  }

  List<ShiftAlert> build({
    required List<Shift> shifts,
    required List<CalendarBusyPeriod> calendarPeriods,
    required Map<String, ShiftAlertDecision> decisions,
  }) {
    final alerts = <ShiftAlert>[];
    final offShifts = shifts.where((shift) => shift.isOffDuty).toList();

    for (final off in offShifts) {
      final night = shifts.cast<Shift?>().firstWhere(
        (shift) => shift?.sourceKey == off.linkedShiftKey,
        orElse: () => null,
      );
      final id = 'off|${off.sourceKey}';
      alerts.add(
        ShiftAlert(
          id: id,
          type: ShiftAlertType.offAfterNight,
          title: 'เวรออฟหลังเวรดึก',
          message:
              '${night?.code ?? 'เวรดึก'} สิ้นสุดเวลา 08:00 '
              'ช่วง 08:00–16:00 เป็นเวรออฟและไม่ควรรับเวรต่อ',
          start: off.start,
          end: off.end,
          decision: decisions[id] ?? ShiftAlertDecision.pending,
          primaryShiftKey: night?.sourceKey,
          targetShiftKey: off.sourceKey,
          offShiftKey: off.sourceKey,
        ),
      );
    }

    for (var i = 0; i < shifts.length; i++) {
      for (var j = i + 1; j < shifts.length; j++) {
        final first = shifts[i];
        final second = shifts[j];
        if (first.excluded || second.excluded) continue;
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
              title: 'เวรชนช่วงออฟ',
              message:
                  '${duty.code} ${_range(duty.start, duty.end)} ชนกับเวรออฟ '
                  '${_range(off.start, off.end)} จึงรับต่อไม่ได้จนกว่าจะยืนยัน',
              start: duty.start.isAfter(off.start) ? duty.start : off.start,
              end: duty.end.isBefore(off.end) ? duty.end : off.end,
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
                '${first.code} ${_range(first.start, first.end)} ชนกับ '
                '${second.code} ${_range(second.start, second.end)}',
            start: second.start.isAfter(first.start)
                ? second.start
                : first.start,
            end: second.end.isBefore(first.end) ? second.end : first.end,
            decision: decisions[id] ?? ShiftAlertDecision.pending,
            primaryShiftKey: first.sourceKey,
            targetShiftKey: second.sourceKey,
          ),
        );
      }
    }

    for (final shift in shifts.where(
      (item) => !item.isOffDuty && !item.excluded,
    )) {
      for (final period in calendarPeriods) {
        if (period.legacyKey == CalendarService.legacyKeyFor(shift) ||
            !_overlaps(shift.start, shift.end, period.start, period.end)) {
          continue;
        }
        final id =
            'calendar-overlap|${shift.sourceKey}|${period.id}|'
            '${period.start.toIso8601String()}';
        alerts.add(
          ShiftAlert(
            id: id,
            type: ShiftAlertType.calendarOverlap,
            title: 'เวรชนกิจกรรมใน Calendar',
            message:
                '${shift.code} ${_range(shift.start, shift.end)} ชนกับ '
                '“${period.title}” ${_range(period.start, period.end)}',
            start: shift.start.isAfter(period.start)
                ? shift.start
                : period.start,
            end: shift.end.isBefore(period.end) ? shift.end : period.end,
            decision: decisions[id] ?? ShiftAlertDecision.pending,
            primaryShiftKey: shift.sourceKey,
            targetShiftKey: shift.sourceKey,
          ),
        );
      }
    }

    alerts.sort((a, b) {
      final pending = (a.isPending ? 0 : 1).compareTo(b.isPending ? 0 : 1);
      return pending != 0 ? pending : a.start.compareTo(b.start);
    });
    return alerts;
  }

  bool _overlaps(
    DateTime firstStart,
    DateTime firstEnd,
    DateTime secondStart,
    DateTime secondEnd,
  ) => firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);

  String _range(DateTime start, DateTime end) =>
      '${_date(start)} ${_time(start)}–${_time(end)}';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
