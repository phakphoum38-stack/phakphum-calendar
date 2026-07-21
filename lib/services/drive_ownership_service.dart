import 'package:googleapis/drive/v3.dart' as drive;

import 'google_api_client.dart';

class RecentOwnedSheet {
  const RecentOwnedSheet({
    required this.id,
    required this.name,
    required this.url,
    this.modifiedAt,
  });

  final String id;
  final String name;
  final String url;
  final DateTime? modifiedAt;
}

class DriveOwnershipService {
  const DriveOwnershipService();

  static const googleSheetMimeType = 'application/vnd.google-apps.spreadsheet';
  static const recentOwnedSheetsQuery =
      "mimeType = '$googleSheetMimeType' and trashed = false "
      "and 'me' in owners";

  Future<List<RecentOwnedSheet>> listRecentlyModifiedOwnedSpreadsheets(
    GoogleApiClient client, {
    int limit = 20,
  }) async {
    final response = await drive.DriveApi(client).files.list(
      q: recentOwnedSheetsQuery,
      orderBy: 'modifiedByMeTime desc,name',
      corpora: 'user',
      spaces: 'drive',
      pageSize: limit.clamp(1, 50),
      $fields:
          'files(id,name,mimeType,ownedByMe,trashed,modifiedTime,'
          'modifiedByMeTime,webViewLink)',
    );
    return recentOwnedSheetsFromFiles(response.files ?? const []);
  }

  static List<RecentOwnedSheet> recentOwnedSheetsFromFiles(
    Iterable<drive.File> files,
  ) => [
    for (final file in files)
      if (file.id != null &&
          file.id!.isNotEmpty &&
          file.ownedByMe == true &&
          file.trashed != true &&
          file.mimeType == googleSheetMimeType)
        RecentOwnedSheet(
          id: file.id!,
          name: (file.name?.trim().isNotEmpty ?? false)
              ? file.name!.trim()
              : 'Google Sheets',
          url: file.webViewLink?.trim().isNotEmpty == true
              ? file.webViewLink!.trim()
              : 'https://docs.google.com/spreadsheets/d/${file.id}/edit',
          modifiedAt: file.modifiedByMeTime ?? file.modifiedTime,
        ),
  ];

  Future<drive.File> requireOwnedSpreadsheet(
    GoogleApiClient client,
    String fileId,
  ) async {
    final file =
        await drive.DriveApi(client).files.get(
              fileId,
              supportsAllDrives: true,
              $fields: 'id,name,mimeType,ownedByMe,trashed',
            )
            as drive.File;
    validateOwnedSpreadsheet(file);
    return file;
  }

  static void validateOwnedSpreadsheet(drive.File file) {
    if (file.trashed == true) {
      throw StateError('ไฟล์ต้นฉบับอยู่ในถังขยะของ Google Drive');
    }
    if (file.mimeType != googleSheetMimeType) {
      throw StateError('ไฟล์ต้นฉบับต้องเป็น Google Sheets');
    }
    if (file.ownedByMe != true) {
      throw StateError(
        'ไฟล์ต้นฉบับต้องเป็นของบัญชี Google ที่ล็อกอินอยู่ '
        'ไม่สามารถใช้ไฟล์ที่เป็นของบัญชีอื่นได้',
      );
    }
  }
}
