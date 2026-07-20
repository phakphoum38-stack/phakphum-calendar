import 'package:googleapis/sheets/v4.dart' as sheets;

import '../models/shift.dart';
import 'google_api_client.dart';

class SheetsService {
  final Map<String, List<String>> _titleCache = {};

  static String spreadsheetIdFromUrl(String input) {
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9_-]+)').firstMatch(input);
    if (match != null) return match.group(1)!;
    if (RegExp(r'^[a-zA-Z0-9_-]{20,}$').hasMatch(input.trim())) {
      return input.trim();
    }
    throw const FormatException('ลิงก์ Google Sheets ไม่ถูกต้อง');
  }

  Future<List<SheetSnapshot>> readAll(
    GoogleApiClient client,
    String sourceUrl,
  ) async {
    final id = spreadsheetIdFromUrl(sourceUrl);
    final api = sheets.SheetsApi(client);
    var titles = _titleCache[id];
    if (titles == null) {
      final metadata = await api.spreadsheets.get(
        id,
        includeGridData: false,
        $fields: 'sheets(properties(sheetId,title,hidden))',
      );
      titles = [
        for (final sheet in metadata.sheets ?? const <sheets.Sheet>[])
          if ((sheet.properties?.title ?? '').isNotEmpty &&
              sheet.properties?.hidden != true)
            sheet.properties!.title!,
      ];
      _titleCache[id] = titles;
    }
    final ranges = [
      for (final title in titles) "'${title.replaceAll("'", "''")}'!A1:AF180",
    ];
    final batch = await api.spreadsheets.values.batchGet(
      id,
      ranges: ranges,
      valueRenderOption: 'FORMATTED_VALUE',
      $fields: 'valueRanges(values)',
    );
    final values = batch.valueRanges ?? const <sheets.ValueRange>[];
    return [
      for (var index = 0; index < titles.length; index++)
        SheetSnapshot(
          title: titles[index],
          rows:
              (index < values.length
                  ? values[index].values
                  : const <List<Object?>>[]) ??
              const <List<Object?>>[],
        ),
    ];
  }

  Future<String> duplicateSheet(
    GoogleApiClient client, {
    required String sourceUrl,
    required String templateTitle,
    required String newTitle,
  }) async {
    final id = spreadsheetIdFromUrl(sourceUrl);
    final api = sheets.SheetsApi(client);
    final metadata = await api.spreadsheets.get(
      id,
      includeGridData: false,
      $fields: 'sheets(properties(sheetId,title,index))',
    );
    final source = (metadata.sheets ?? const <sheets.Sheet>[])
        .where((sheet) => sheet.properties?.title == templateTitle)
        .firstOrNull;
    if (source?.properties?.sheetId == null) {
      throw StateError('ไม่พบแท็บต้นแบบ “$templateTitle”');
    }
    final duplicateExists = (metadata.sheets ?? const <sheets.Sheet>[]).any(
      (sheet) => sheet.properties?.title == newTitle,
    );
    if (duplicateExists) throw StateError('มีแท็บชื่อ “$newTitle” อยู่แล้ว');

    final response = await api.spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest(
        requests: [
          sheets.Request(
            duplicateSheet: sheets.DuplicateSheetRequest(
              sourceSheetId: source!.properties!.sheetId,
              newSheetName: newTitle,
            ),
          ),
        ],
      ),
      id,
      $fields: 'replies(duplicateSheet(properties(title)))',
    );
    _titleCache.remove(id);
    return response.replies?.firstOrNull?.duplicateSheet?.properties?.title ??
        newTitle;
  }
}
