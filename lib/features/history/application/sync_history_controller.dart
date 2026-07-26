import 'package:flutter/foundation.dart';

import '../../../core/state/controller_state.dart';
import '../domain/sync_history_entry.dart';
import '../domain/sync_history_repository.dart';

class SyncHistoryController extends ChangeNotifier implements ControllerState {
  SyncHistoryController(this._repository);

  final SyncHistoryRepository _repository;

  List<SyncHistoryEntry> _entries = const <SyncHistoryEntry>[];
  bool _isLoading = false;
  String? _message;

  List<SyncHistoryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  @override
  String? get message => _message;

  @override
  bool get loading => _isLoading;

  @override
  Object? get error => _message;

  @override
  bool get success => !_isLoading && _message == null;

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
