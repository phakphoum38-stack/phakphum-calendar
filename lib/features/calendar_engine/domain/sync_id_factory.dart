import 'dart:convert';

import 'package:crypto/crypto.dart';

class SyncIdFactory {
  const SyncIdFactory();

  String create({
    required String spreadsheetId,
    required int sheetId,
    required String cellA1,
    required DateTime date,
    required String category,
    required String period,
  }) {
    final canonical = <String>[
      spreadsheetId.trim(),
      sheetId.toString(),
      cellA1.trim().toUpperCase(),
      _dateOnly(date),
      category.trim().toLowerCase(),
      period.trim().toLowerCase(),
    ].join('|');

    final digest = sha256.convert(utf8.encode(canonical));

    return 'sce-${digest.toString().substring(0, 32)}';
  }

  String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
