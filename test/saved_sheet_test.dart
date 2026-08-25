import 'package:flutter_test/flutter_test.dart';
import 'package:phakphum_calendar/models/saved_sheet.dart';

void main() {
  final savedAt = DateTime(2026, 8, 25, 10, 30);

  SavedSheet sheet({bool isActive = false}) => SavedSheet(
        ownerAccountId: 'account-a',
        spreadsheetId: 'spreadsheet-a',
        spreadsheetTitle: 'Roster',
        sheetId: 123,
        sheetTitle: 'August',
        url: 'https://docs.google.com/spreadsheets/d/spreadsheet-a/edit',
        savedAt: savedAt,
        isActive: isActive,
      );

  test('round-trips the active flag', () {
    final restored = SavedSheet.fromJson(sheet(isActive: true).toJson());
    expect(restored.isActive, isTrue);
    expect(restored.key, sheet().key);
  });

  test('legacy records without isActive are inactive migration candidates', () {
    final restored = SavedSheet.fromJson({
      'ownerAccountId': 'account-a',
      'spreadsheetId': 'spreadsheet-a',
      'spreadsheetTitle': 'Roster',
      'sheetId': 123,
      'sheetTitle': 'August',
      'url': 'https://docs.google.com/spreadsheets/d/spreadsheet-a/edit',
      'savedAt': savedAt.toIso8601String(),
    });

    expect(restored.isActive, isFalse);
  });

  test('copyWith changes active state without changing the source identity', () {
    final active = sheet().copyWith(isActive: true);

    expect(active.isActive, isTrue);
    expect(active.key, sheet().key);
    expect(active.ownerAccountId, sheet().ownerAccountId);
    expect(active.spreadsheetId, sheet().spreadsheetId);
  });
}
