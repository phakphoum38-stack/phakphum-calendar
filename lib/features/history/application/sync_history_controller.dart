import 'package:flutter/foundation.dart';

import '../domain/sync_history_entry.dart';
import '../domain/sync_history_repository.dart';

class SyncHistoryController extends ChangeNotifier {
  SyncHistoryController(this._repository);

  final SyncHistoryRepository _repository;

  List<SyncHistoryEntry> _entries =
      const <SyncHistoryEntry>[];
  bool _isLoading = false;
  String? _message;

  List<SyncHistoryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<void> load() async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      _entries = await _repository.list();
    } catch (_) {
      _message = 'โหลดประวัติการซิงก์ไม่สำเร็จ';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
