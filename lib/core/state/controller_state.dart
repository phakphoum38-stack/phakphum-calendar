abstract interface class ControllerState {
  bool get loading;
  Object? get error;
  bool get success;
  String? get message;
}
