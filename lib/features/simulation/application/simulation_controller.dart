import 'package:flutter/foundation.dart';

import '../domain/simulation_plan.dart';

enum SimulationStatus {
  idle,
  loading,
  ready,
  confirming,
  completed,
  failure,
}

class SimulationController extends ChangeNotifier {
  SimulationStatus _status = SimulationStatus.idle;
  SimulationPlan? _plan;
  String? _message;

  SimulationStatus get status => _status;
  SimulationPlan? get plan => _plan;
  String? get message => _message;

  void load(SimulationPlan plan) {
    _plan = plan;
    _status = SimulationStatus.ready;
    _message = null;
    notifyListeners();
  }

  Future<void> confirm(
    Future<void> Function(SimulationPlan plan) synchronization,
  ) async {
    final currentPlan = _plan;
    if (currentPlan == null || !currentPlan.summary.canSynchronize) {
      _message =
          'ไม่สามารถซิงก์ได้ เนื่องจากยังมีรายการที่ถูกบล็อก';
      notifyListeners();
      return;
    }

    _status = SimulationStatus.confirming;
    _message = null;
    notifyListeners();

    try {
      await synchronization(currentPlan);
      _status = SimulationStatus.completed;
      _message = 'อัปเดต Google Calendar สำเร็จ';
    } catch (_) {
      _status = SimulationStatus.failure;
      _message =
          'อัปเดต Google Calendar ไม่สำเร็จ กรุณาตรวจสอบสิทธิ์และลองอีกครั้ง';
    }

    notifyListeners();
  }

  void reset() {
    _status = SimulationStatus.idle;
    _plan = null;
    _message = null;
    notifyListeners();
  }
}
