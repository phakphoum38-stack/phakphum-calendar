import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/core/di/app_dependencies.dart';
import 'package:phakphum_calendar/core/result/result.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/features/excel_import/application/import_engine.dart';
import 'package:phakphum_calendar/features/excel_import/domain/column_mapping.dart';
import 'package:phakphum_calendar/features/excel_import/domain/excel_cell.dart';
import 'package:phakphum_calendar/features/excel_import/domain/excel_row.dart';
import 'package:phakphum_calendar/features/excel_import/presentation/pages/import_summary_page.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_severity.dart';
import 'package:phakphum_calendar/features/rules/domain/rule_violation.dart';
import 'package:phakphum_calendar/features/rules/domain/schedule_rules.dart';
import 'package:phakphum_calendar/features/schedule/data/shared_preferences_schedule_repository.dart';

import 'support/in_memory_schedule_store.dart';

void main() {
  const engine = ImportEngine();
  const mapping = ColumnMapping(
    dateColumn: 'A',
    shiftColumn: 'B',
    employeeColumn: 'C',
    departmentColumn: 'D',
    locationColumn: 'E',
    notesColumn: 'F',
  );

  test(
    'Excel import creates and persists one canonical calendar source',
    () async {
      final imported = engine.convertRows(
        rows: _rows([
          ['Date', 'Shift', 'Employee', 'Department', 'Location', 'Notes'],
          ['24/07/2026', 'Morning', 'Anan', 'ER', 'Ward A', 'Charge'],
          ['01/08/2026', 'Night', 'Mali', 'ICU', 'Ward B', 'Training'],
        ]),
        mapping: mapping,
      );
      final dependencies = _dependencies();

      final schedule = dependencies.createImportedSchedule(imported.records);
      final persisted = await dependencies.saveImportedSchedule(schedule);
      final controller = dependencies.createImportedScheduleController(
        schedule,
      );
      addTearDown(controller.dispose);
      final beforeValidation = controller.canonicalSchedule;
      final validation = controller.validateSchedule();

      expect(schedule, isA<Schedule>());
      expect(persisted.isSuccess, isTrue);
      expect(schedule.months.map((month) => month.month), [
        DateTime(2026, 7),
        DateTime(2026, 8),
      ]);
      expect(controller.canonicalSchedule, same(schedule));
      expect(controller.currentMonth, DateTime(2026, 7));
      final assignment = controller.schedule
          .day(DateTime(2026, 7, 24))!
          .assignments
          .single;
      expect(assignment.employee.firstName, 'Anan');
      expect(assignment.employee.department.name, 'ER');
      expect(assignment.shift.name, 'Morning');
      expect(assignment.location, 'Ward A');
      expect(assignment.remark, 'Charge');
      expect(validation, same(controller.validationResult));
      expect(validation!.errors, hasLength(2));
      expect(
        validation.errors.map((violation) => violation.ruleId),
        everyElement('invalid-shift-duration'),
      );
      expect(controller.canonicalSchedule, same(beforeValidation));

      final restoredController = dependencies.createImportedScheduleController(
        Schedule(id: 'temporary', name: 'Temporary'),
      );
      addTearDown(restoredController.dispose);
      final restored = await restoredController.loadPersistedSchedule();
      expect(restored.isSuccess, isTrue);
      expect(
        _scheduleValues(restoredController.canonicalSchedule),
        _scheduleValues(schedule),
      );

      controller.nextMonth();
      expect(controller.schedule.month, DateTime(2026, 8));
      expect(
        controller.schedule
            .day(DateTime(2026, 8, 1))!
            .assignments
            .single
            .employee
            .firstName,
        'Mali',
      );

      final augustAssignment = controller.schedule
          .day(DateTime(2026, 8, 1))!
          .assignments
          .single;
      controller.updateAssignment(
        DateTime(2026, 8, 1),
        augustAssignment.copyWith(remark: 'Updated in calendar'),
      );
      expect(controller.validationResult, isNull);
      expect((await controller.saveSchedule()).isSuccess, isTrue);
      final edited = await dependencies.scheduleRepository.findById('imported');
      expect(
        (edited as Success<Schedule?>).value!
            .month(DateTime(2026, 8))!
            .day(DateTime(2026, 8, 1))!
            .assignments
            .single
            .remark,
        'Updated in calendar',
      );
    },
  );

  testWidgets(
    'summary route uses injected validation once and preserves rule order',
    (tester) async {
      final executionOrder = <String>[];
      final first = CustomRule(
        id: 'first',
        name: 'First',
        severity: RuleSeverity.warning,
        evaluator: (context) {
          executionOrder.add('first');
          return const [];
        },
      );
      final duplicateFirst = CustomRule(
        id: 'first',
        name: 'Duplicate first',
        severity: RuleSeverity.warning,
        evaluator: (context) {
          executionOrder.add('duplicate-first');
          return const [];
        },
      );
      final second = CustomRule(
        id: 'second',
        name: 'Second',
        severity: RuleSeverity.warning,
        evaluator: (context) {
          executionOrder.add('second');
          return const <RuleViolation>[];
        },
      );
      final dependencies = AppDependencies(
        scheduleRules: [first, duplicateFirst, second],
        scheduleRepository: SharedPreferencesScheduleRepository(
          store: InMemoryScheduleKeyValueStore(),
        ),
      );
      final imported = engine.convertRows(
        rows: _rows([
          ['Date', 'Shift', 'Employee', 'Department', 'Location', 'Notes'],
          ['24/07/2026', 'Morning', 'Anan', 'ER', '', ''],
        ]),
        mapping: mapping,
      );
      final schedule = dependencies.createImportedSchedule(imported.records);

      await tester.pumpWidget(
        MaterialApp(
          home: ImportSummaryPage(
            summary: imported.summary,
            records: imported.records,
            schedule: schedule,
            scheduleControllerFactory:
                dependencies.createImportedScheduleController,
          ),
        ),
      );
      await tester.tap(find.text('View Month Calendar'));
      await tester.pumpAndSettle();

      expect(find.text('Month Calendar'), findsOneWidget);
      expect(executionOrder, ['first', 'second']);
    },
  );

  test(
    'successful empty import persists a valid empty canonical calendar',
    () async {
      final dependencies = _dependencies();

      final schedule = dependencies.createImportedSchedule(const []);
      final persisted = await dependencies.saveImportedSchedule(schedule);
      final controller = dependencies.createImportedScheduleController(
        schedule,
      );
      addTearDown(controller.dispose);

      expect(schedule.months, isEmpty);
      expect(persisted.isSuccess, isTrue);
      expect(controller.canonicalSchedule.id, 'imported');
      expect(controller.schedule.days, isNotEmpty);
      expect(controller.hasAssignments, isFalse);
    },
  );
}

AppDependencies _dependencies() {
  return AppDependencies(
    scheduleRepository: SharedPreferencesScheduleRepository(
      store: InMemoryScheduleKeyValueStore(),
    ),
  );
}

List<String> _scheduleValues(Schedule schedule) {
  return [
    schedule.id,
    schedule.name,
    for (final month in schedule.months)
      for (final day in month.days)
        for (final assignment in day.assignments)
          '${day.date.toIso8601String()}|${assignment.employee.id}|'
              '${assignment.shift.id}|${assignment.location}|'
              '${assignment.remark}',
  ];
}

List<ExcelRow> _rows(List<List<Object?>> values) {
  return [
    for (var rowIndex = 0; rowIndex < values.length; rowIndex++)
      ExcelRow(
        index: rowIndex,
        cells: [
          for (
            var columnIndex = 0;
            columnIndex < values[rowIndex].length;
            columnIndex++
          )
            ExcelCell(
              rowIndex: rowIndex,
              columnIndex: columnIndex,
              value: values[rowIndex][columnIndex],
            ),
        ],
      ),
  ];
}
