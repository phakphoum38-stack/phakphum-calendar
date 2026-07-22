import 'package:flutter/foundation.dart';

import '../domain/authentication_service.dart';
import '../domain/authentication_state.dart';

class AuthenticationController extends ChangeNotifier {
  AuthenticationController(this._service);

  final AuthenticationService _service;

  AuthenticationState _state = const AuthenticationState.uninitialized();

  AuthenticationState get state => _state;

  Future<void> initialize() async {
    try {
      await _service.initialize();
      final user = await _service.restoreSession();
      _state = AuthenticationState(
        status: user == null
            ? AuthenticationStatus.signedOut
            : AuthenticationStatus.signedIn,
        user: user,
      );
    } catch (error) {
      _state = AuthenticationState(
        status: AuthenticationStatus.failure,
        message: _friendlyMessage(error),
      );
    }
    notifyListeners();
  }

  Future<void> signIn() async {
    _state = const AuthenticationState(
      status: AuthenticationStatus.signingIn,
    );
    notifyListeners();

    try {
      final user = await _service.signIn();
      _state = AuthenticationState(
        status: AuthenticationStatus.signedIn,
        user: user,
      );
    } catch (error) {
      _state = AuthenticationState(
        status: AuthenticationStatus.failure,
        message: _friendlyMessage(error),
      );
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _service.signOut();
    _state = const AuthenticationState(
      status: AuthenticationStatus.signedOut,
    );
    notifyListeners();
  }

  String _friendlyMessage(Object error) {
    if (error is UnsupportedError) {
      return error.message?.toString() ??
          'แพลตฟอร์มนี้ยังไม่รองรับขั้นตอนเข้าสู่ระบบแบบปัจจุบัน';
    }

    return 'เข้าสู่ระบบ Google ไม่สำเร็จ กรุณาตรวจสอบการตั้งค่า OAuth '
        'และลองอีกครั้ง';
  }
}
