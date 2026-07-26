import 'dart:convert';

import '../../../domain/entities/shift_template.dart';

/// Controlled decoding error for persisted shift-template data.
class ShiftTemplateCodecException implements Exception {
  const ShiftTemplateCodecException(this.message);

  final String message;
}

/// Versioned JSON codec for [ShiftTemplate].
class ShiftTemplateJsonCodec {
  const ShiftTemplateJsonCodec();

  static const formatVersion = 1;

  String encode(List<ShiftTemplate> templates) {
    final ordered = List<ShiftTemplate>.of(templates)
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return jsonEncode({
      'formatVersion': formatVersion,
      'templates': [
        for (final template in ordered)
          {
            'id': template.id,
            'code': template.code,
            'name': template.name,
            'shortName': template.shortName,
            'description': template.description,
            'startMinutes': template.startTime.inMinutes,
            'endMinutes': template.endTime.inMinutes,
            'color': template.color,
            'workingHours': template.workingHours,
            'location': template.location,
            'defaultCalendarId': template.defaultCalendarId,
            'reminderMinutes': template.reminderMinutes,
            'rate': template.rate,
            'active': template.active,
            'sortOrder': template.sortOrder,
          },
      ],
    });
  }

  List<ShiftTemplate> decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw ShiftTemplateCodecException('Malformed template JSON: $error');
    }
    if (decoded is! Map<String, Object?>) {
      throw const ShiftTemplateCodecException(
        'Template root must be an object.',
      );
    }
    if (decoded['formatVersion'] != formatVersion) {
      throw ShiftTemplateCodecException(
        'Unsupported template format version ${decoded['formatVersion']}.',
      );
    }
    final raw = decoded['templates'];
    if (raw is! List<Object?>) {
      throw const ShiftTemplateCodecException('templates must be a list.');
    }
    final byId = <String, ShiftTemplate>{};
    for (var index = 0; index < raw.length; index++) {
      final item = raw[index];
      if (item is! Map<String, Object?>) {
        throw ShiftTemplateCodecException(
          'templates[$index] must be an object.',
        );
      }
      final template = _decodeTemplate(item, index);
      if (byId.containsKey(template.id)) {
        throw ShiftTemplateCodecException(
          'Duplicate template ID "${template.id}".',
        );
      }
      byId[template.id] = template;
    }
    return List.unmodifiable(byId.values);
  }

  ShiftTemplate _decodeTemplate(Map<String, Object?> value, int index) {
    String string(String key, {bool required = false}) {
      final item = value[key];
      if (item is! String || (required && item.trim().isEmpty)) {
        throw ShiftTemplateCodecException(
          'templates[$index].$key must be a valid string.',
        );
      }
      return item;
    }

    int integer(String key) {
      final item = value[key];
      if (item is! int) {
        throw ShiftTemplateCodecException(
          'templates[$index].$key must be an integer.',
        );
      }
      return item;
    }

    double number(String key) {
      final item = value[key];
      if (item is! num) {
        throw ShiftTemplateCodecException(
          'templates[$index].$key must be a number.',
        );
      }
      return item.toDouble();
    }

    String? optionalString(String key) {
      final item = value[key];
      if (item == null) return null;
      if (item is! String) {
        throw ShiftTemplateCodecException(
          'templates[$index].$key must be a string or null.',
        );
      }
      return item;
    }

    final active = value['active'];
    if (active is! bool) {
      throw ShiftTemplateCodecException(
        'templates[$index].active must be a boolean.',
      );
    }
    final reminder = value['reminderMinutes'];
    if (reminder != null && reminder is! int) {
      throw ShiftTemplateCodecException(
        'templates[$index].reminderMinutes must be an integer or null.',
      );
    }
    return ShiftTemplate(
      id: string('id', required: true),
      code: string('code', required: true),
      name: string('name', required: true),
      shortName: string('shortName', required: true),
      description: string('description'),
      startTime: Duration(minutes: integer('startMinutes')),
      endTime: Duration(minutes: integer('endMinutes')),
      color: integer('color'),
      workingHours: number('workingHours'),
      location: optionalString('location'),
      defaultCalendarId: optionalString('defaultCalendarId'),
      reminderMinutes: reminder as int?,
      rate: number('rate'),
      active: active,
      sortOrder: integer('sortOrder'),
    );
  }
}
