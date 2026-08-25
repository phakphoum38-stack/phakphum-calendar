import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

enum OwnedSheetOrder { firstCreated, recentlyModified }

class RecentOwnedSheet {
  const RecentOwnedSheet({
    required this.id,
    required this.name,
    required this.url,
    this.createdAt,
    this.modifiedAt,
  });

  final String id;
  final String name;
  final String url;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
}

/// Lists accessible Google Sheets files and validates read access.
abstract interface class DriveOwnershipGateway {
  Future<List<RecentOwnedSheet>> listOwnedSpreadsheets(
    http.Client client, {
    int limit = 20,
    OwnedSheetOrder order = OwnedSheetOrder.recentlyModified,
  });

  /// Returns the first Google Sheets file created in each calendar month.
  Future<List<RecentOwnedSheet>> listFirstSpreadsheetOfEachMonth(
    http.Client client, {
    int limit = 1000,
  });

  /// Kept for API compatibility. The check now accepts any readable Sheet.
  Future<drive.File> requireOwnedSpreadsheet(http.Client client, String fileId);
}

class DriveOwnershipService implements DriveOwnershipGateway {
  const DriveOwnershipService();

  static const googleSheetMimeType = 'application/vnd.google-apps.spreadsheet';
  static const recentOwnedSheetsQuery =
      "mimeType = '$googleSheetMimeType' and trashed = false";

  @override
  Future<List<RecentOwnedSheet>> listOwnedSpreadsheets(
    http.Client client, {
    int limit = 20,
    OwnedSheetOrder order = OwnedSheetOrder.recentlyModified,
  }) async {
    final response = await drive.DriveApi(client).files.list(
      q: recentOwnedSheetsQuery,
      orderBy: switch (order) {
        OwnedSheetOrder.firstCreated => 'createdTime,name',
        OwnedSheetOrder.recentlyModified => 'modifiedTime desc,name',
      },
      corpora: 'user',
      spaces: 'drive',
      pageSize: limit.clamp(1, 1000),
      $fields:
          'files(id,name,mimeType,ownedByMe,trashed,createdTime,modifiedTime,'
          'modifiedByMeTime,webViewLink)',
    );
    return recentOwnedSheetsFromFiles(response.files ?? const []);
  }

  @override
  Future<List<RecentOwnedSheet>> listFirstSpreadsheetOfEachMonth(
    http.Client client, {
    int limit = 1000,
  }) async {
    final files = <drive.File>[];
    String? pageToken;

    do {
      final response = await drive.DriveApi(client).files.list(
        q: recentOwnedSheetsQuery,
        orderBy: 'createdTime,name',
        corpora: 'user',
        spaces: 'drive',
        pageSize: limit.clamp(1, 1000),
        pageToken: pageToken,
        $fields:
            'nextPageToken,files(id,name,mimeType,ownedByMe,trashed,'
            'createdTime,modifiedTime,modifiedByMeTime,webViewLink)',
      );
      files.addAll(response.files ?? const <drive.File>[]);
      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    final accessibleFiles = files.where(_isReadableGoogleSheet).toList()
      ..sort((left, right) {
        final leftDate = left.createdTime;
        final rightDate = right.createdTime;
        if (leftDate == null && rightDate == null) return 0;
        if (leftDate == null) return 1;
        if (rightDate == null) return -1;
        return leftDate.compareTo(rightDate);
      });

    final firstByMonth = <String, drive.File>{};
    for (final file in accessibleFiles) {
      final createdAt = file.createdTime;
      if (createdAt == null) continue;
      final localDate = createdAt.toLocal();
      final monthKey =
          '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}';
      firstByMonth.putIfAbsent(monthKey, () => file);
    }

    final results = firstByMonth.values.map(_toRecentOwnedSheet).toList()
      ..sort((left, right) {
        final leftDate = left.createdAt;
        final rightDate = right.createdAt;
        if (leftDate == null && rightDate == null) return 0;
        if (leftDate == null) return 1;
        if (rightDate == null) return -1;
        return rightDate.compareTo(leftDate);
      });

    return results;
  }

  Future<List<RecentOwnedSheet>> listRecentlyModifiedOwnedSpreadsheets(
    http.Client client, {
    int limit = 20,
  }) => listOwnedSpreadsheets(client, limit: limit);

  static List<RecentOwnedSheet> recentOwnedSheetsFromFiles(
    Iterable<drive.File> files,
  ) => [
    for (final file in files)
      if (_isReadableGoogleSheet(file)) _toRecentOwnedSheet(file),
  ];

  static bool _isReadableGoogleSheet(drive.File file) {
    return file.id != null &&
        file.id!.isNotEmpty &&
        file.trashed != true &&
        file.mimeType == googleSheetMimeType;
  }

  static RecentOwnedSheet _toRecentOwnedSheet(drive.File file) {
    return RecentOwnedSheet(
      id: file.id!,
      name: (file.name?.trim().isNotEmpty ?? false)
          ? file.name!.trim()
          : 'Google Sheets',
      url: file.webViewLink?.trim().isNotEmpty == true
          ? file.webViewLink!.trim()
          : 'https://docs.google.com/spreadsheets/d/${file.id}/edit',
      createdAt: file.createdTime,
      modifiedAt: file.modifiedByMeTime ?? file.modifiedTime,
    );
  }

  @override
  Future<drive.File> requireOwnedSpreadsheet(
    http.Client client,
    String fileId,
  ) async {
    final normalizedFileId = fileId.replaceAll(RegExp(r'\s+'), '');
    if (normalizedFileId.isEmpty) {
      throw StateError('ไม่พบรหัสไฟล์ Google Sheets');
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(normalizedFileId)) {
      throw const FormatException('รหัสไฟล์ Google Sheets ไม่ถูกต้อง');
    }

    try {
      final file =
          await drive.DriveApi(client).files.get(
                normalizedFileId,
                supportsAllDrives: true,
                $fields: 'id,name,mimeType,ownedByMe,trashed,webViewLink',
              )
              as drive.File;
      validateOwnedSpreadsheet(file);
      return file;
    } on drive.DetailedApiRequestError catch (error) {
      if (error.status == 404) {
        throw StateError(
          'ไม่พบไฟล์ Google Sheets หรือบัญชีนี้ไม่มีสิทธิ์เข้าถึง '
          'กรุณาเลือกไฟล์ใหม่จาก Google Drive',
        );
      }
      rethrow;
    }
  }

  /// Kept with the old name to avoid breaking existing callers.
  static void validateOwnedSpreadsheet(drive.File file) {
    if (file.trashed == true) {
      throw StateError('ไฟล์ต้นฉบับอยู่ในถังขยะของ Google Drive');
    }
    if (file.mimeType != googleSheetMimeType) {
      throw StateError('ไฟล์ต้นฉบับต้องเป็น Google Sheets');
    }
  }
}
