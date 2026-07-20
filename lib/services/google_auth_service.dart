import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_api_client.dart';

class GoogleAuthService extends ChangeNotifier {
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  GoogleSignInAccount? _account;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _initialized = false;
  String? _error;

  GoogleSignInAccount? get account => _account;
  bool get isSignedIn => _account != null;
  bool get initialized => _initialized;
  String? get error => _error;
  bool get oauthConfigured => !kIsWeb || _webClientId.isNotEmpty;

  Future<void> initialize() async {
    if (_initialized) return;
    final signIn = GoogleSignIn.instance;
    _subscription = signIn.authenticationEvents.listen(
      (event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _account = event.user;
            _error = null;
          case GoogleSignInAuthenticationEventSignOut():
            _account = null;
        }
        notifyListeners();
      },
      onError: (Object error) {
        _error = _friendlyError(error);
        notifyListeners();
      },
    );

    try {
      if (kIsWeb && _webClientId.isEmpty) {
        _error = 'โหมดเว็บยังไม่ได้ตั้งค่า GOOGLE_WEB_CLIENT_ID';
        _initialized = true;
        notifyListeners();
        return;
      }
      final clientId = kIsWeb
          ? (_webClientId.isEmpty ? null : _webClientId)
          : (defaultTargetPlatform == TargetPlatform.iOS &&
                    _iosClientId.isNotEmpty
                ? _iosClientId
                : null);
      await signIn.initialize(
        clientId: clientId,
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );
      _initialized = true;
      notifyListeners();
      final attempt = signIn.attemptLightweightAuthentication();
      if (attempt != null) await attempt;
    } catch (error) {
      _error = _friendlyError(error);
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    _error = null;
    notifyListeners();
    try {
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw StateError('กรุณาใช้ปุ่ม Google ที่แสดงบนหน้าเว็บ');
      }
      await GoogleSignIn.instance.authenticate();
    } catch (error) {
      _error = _friendlyError(error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _account = null;
    notifyListeners();
  }

  Future<GoogleApiClient> clientFor(
    List<String> scopes, {
    bool promptIfNecessary = true,
  }) async {
    final current = _account;
    if (current == null) {
      throw StateError('กรุณาเข้าสู่ระบบ Google ก่อน');
    }
    final headers = await current.authorizationClient.authorizationHeaders(
      scopes,
      promptIfNecessary: promptIfNecessary,
    );
    if (headers == null) {
      throw StateError('ยังไม่ได้อนุญาตสิทธิ์ที่จำเป็น');
    }
    return GoogleApiClient(headers);
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('clientId') || text.contains('client_id')) {
      return 'ยังไม่ได้ตั้งค่า Google OAuth Client ID';
    }
    return text.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
