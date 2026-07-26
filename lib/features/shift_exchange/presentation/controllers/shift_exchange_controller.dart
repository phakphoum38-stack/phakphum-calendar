import 'package:flutter/foundation.dart';

import '../../domain/shift_exchange_request.dart';

/// Controls the visible exchange-request status without mutating schedules.
class ShiftExchangeController extends ChangeNotifier {
  ShiftExchangeController({List<ShiftExchangeRequest> requests = const []})
    : _requests = List.unmodifiable(requests);

  List<ShiftExchangeRequest> _requests;
  ShiftExchangeStatus? _status;

  /// Currently selected status, or null for all requests.
  ShiftExchangeStatus? get status => _status;

  /// Requests matching the selected status in deterministic newest-first order.
  List<ShiftExchangeRequest> get requests {
    final result =
        _requests
            .where((request) => _status == null || request.status == _status)
            .toList()
          ..sort((left, right) {
            final created = right.createdAt.compareTo(left.createdAt);
            return created != 0 ? created : left.id.compareTo(right.id);
          });
    return List.unmodifiable(result);
  }

  /// Replaces request snapshots supplied by the application boundary.
  void updateRequests(List<ShiftExchangeRequest> value) {
    _requests = List.unmodifiable(value);
    notifyListeners();
  }

  /// Filters requests by status.
  void updateStatus(ShiftExchangeStatus? value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }
}
