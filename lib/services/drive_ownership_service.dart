import 'package:googleapis/drive/v3.dart' as drive;

import 'google_api_client.dart';

class DriveOwnershipService {
  const DriveOwnershipService();

  static const googleSheetMimeType = 'application/vnd.google-apps.spreadsheet';

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
