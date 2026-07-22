import 'package:flutter/foundation.dart';

import '../domain/drive_gateway.dart';
import '../domain/roster_file.dart';
import 'roster_selection_state.dart';

class RosterSelectionController extends ChangeNotifier {
  RosterSelectionController(this._gateway);

  final DriveGateway _gateway;

  RosterSelectionState _selection = const RosterSelectionState();
  List<RosterFile> _availableFiles = const <RosterFile>[];
  bool _isLoading = false;
  String? _errorMessage;

  RosterSelectionState get selection => _selection;
  List<RosterFile> get availableFiles => _availableFiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSpreadsheets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableFiles = await _gateway.listSpreadsheets();
    } catch (_) {
      _errorMessage =
          'โหลดรายการ Google Sheets ไม่สำเร็จ กรุณาตรวจสอบสิทธิ์ Drive';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void select({required RosterFileSlot slot, required RosterFile file}) {
    _selection = switch (slot) {
      RosterFileSlot.original => _selection.copyWith(original: file),
      RosterFileSlot.current => _selection.copyWith(current: file),
    };
    notifyListeners();
  }

  void clear(RosterFileSlot slot) {
    _selection = switch (slot) {
      RosterFileSlot.original => _selection.copyWith(clearOriginal: true),
      RosterFileSlot.current => _selection.copyWith(clearCurrent: true),
    };
    notifyListeners();
  }
}
