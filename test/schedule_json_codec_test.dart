import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/domain/entities/schedule.dart';
import 'package:phakphum_calendar/features/schedule/data/schedule_json_codec.dart';

import 'support/canonical_schedule_fixture.dart';

void main() {
  const codec = ScheduleJsonCodec();

  test('empty Schedule encodes and decodes with format version', () {
    final schedule = Schedule(id: 'empty', name: 'Empty');

    final encoded = codec.encode(schedule);
    final decoded = codec.decode(encoded);
    final json = jsonDecode(encoded) as Map<String, Object?>;

    expect(json['format'], ScheduleJsonCodec.format);
    expect(json['version'], ScheduleJsonCodec.schemaVersion);
    expect(decoded.id, 'empty');
    expect(decoded.name, 'Empty');
    expect(decoded.months, isEmpty);
  });

  test('multi-month aggregate round-trips without data loss', () {
    final schedule = canonicalScheduleFixture();

    final decoded = codec.decode(codec.encode(schedule));

    expect(canonicalScheduleValues(decoded), canonicalScheduleValues(schedule));
    expect(decoded.months, hasLength(2));
    expect(decoded.months[1].days, hasLength(31));
    expect(
      decoded.months[1].days.every((day) => day.assignments.isEmpty),
      true,
    );
  });

  test('shared employee and shift references remain logically consistent', () {
    final decoded = codec.decode(codec.encode(canonicalScheduleFixture()));
    final first = decoded.months.first.days[0].assignments.single;
    final second = decoded.months.first.days[1].assignments.single;

    expect(first.employee.id, 'employee-1');
    expect(first.shift.id, 'night');
    expect(identical(first.employee, second.employee), isTrue);
    expect(
      identical(first.employee.department, second.employee.department),
      true,
    );
    expect(identical(first.shift, second.shift), isTrue);
  });

  test('unsupported schema versions fail explicitly', () {
    final json =
        jsonDecode(codec.encode(canonicalScheduleFixture()))
            as Map<String, Object?>;
    json['version'] = 99;

    expect(
      () => codec.decode(jsonEncode(json)),
      throwsA(isA<UnsupportedScheduleVersionException>()),
    );
  });

  test('missing required fields fail with useful context', () {
    final json =
        jsonDecode(codec.encode(canonicalScheduleFixture()))
            as Map<String, Object?>;
    final schedule = json['schedule']! as Map<String, Object?>;
    schedule.remove('id');

    expect(
      () => codec.decode(jsonEncode(json)),
      throwsA(
        isA<ScheduleCodecException>().having(
          (error) => error.message,
          'message',
          contains(r'$.schedule.id'),
        ),
      ),
    );
  });

  test('malformed JSON fails with a controlled format error', () {
    expect(() => codec.decode('{not-json'), throwsA(isA<FormatException>()));
  });
}
