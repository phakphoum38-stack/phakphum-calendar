import '../../core/result/result.dart';

abstract interface class GoogleSheetsService {
  Future<Result<List<List<Object?>>>> readWorksheet({
    required String spreadsheetId,
    required String worksheet,
  });
}
