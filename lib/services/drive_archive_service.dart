import 'package:googleapis/drive/v3.dart' as drive;

import 'google_api_client.dart';

class DriveArchiveResult {
  const DriveArchiveResult({
    required this.id,
    required this.name,
    required this.webViewLink,
    required this.alreadyExisted,
  });

  final String id;
  final String name;
  final String? webViewLink;
  final bool alreadyExisted;
}

class DriveArchiveService {
  const DriveArchiveService();

  static const sourceApp = 'phakphum_shift_calendar';

  Future<DriveArchiveResult> copyMonthlyOriginal(
    GoogleApiClient client, {
    required String sourceFileId,
    required int year,
    required int month,
  }) async {
    final api = drive.DriveApi(client);
    final period =
        '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}';
    final buddhistYear = year + 543;
    final name =
        'ตารางเวร-ต้นฉบับ-$buddhistYear-${month.toString().padLeft(2, '0')}';
    final existing = await api.files.list(
      q:
          "trashed = false and appProperties has { key='sourceApp' "
          "and value='$sourceApp' } and appProperties has { key='period' "
          "and value='$period' }",
      spaces: 'drive',
      pageSize: 1,
      $fields: 'files(id,name,webViewLink)',
    );
    final previous = (existing.files?.isNotEmpty ?? false)
        ? existing.files!.first
        : null;
    if (previous?.id != null) {
      return DriveArchiveResult(
        id: previous!.id!,
        name: previous.name ?? name,
        webViewLink: previous.webViewLink,
        alreadyExisted: true,
      );
    }

    final request = drive.File(
      name: name,
      description:
          'สำเนาต้นฉบับประจำเดือน สร้างโดย Phakphum Shift Calendar; '
          'แอปไม่ได้แก้ไขไฟล์ต้นฉบับ',
      appProperties: {
        'sourceApp': sourceApp,
        'sourceFileId': sourceFileId,
        'period': period,
      },
    );
    final copied = await api.files.copy(
      request,
      sourceFileId,
      supportsAllDrives: true,
      $fields: 'id,name,webViewLink',
    );
    return DriveArchiveResult(
      id: copied.id ?? '',
      name: copied.name ?? name,
      webViewLink: copied.webViewLink,
      alreadyExisted: false,
    );
  }
}
