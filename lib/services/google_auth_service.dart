import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_api_client.dart';

class GoogleAuthService extends ChangeNotifier {
  static const _webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
  static const _iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _macosClientId = String.fromEnvironment(
    'GOOGLE_MACOS_CLIENT_ID',
  );
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  GoogleSignInAccount? _account;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _initialized = false;
  bool _pluginInitialized = false;
  String _runtimeWebClientId = '';
  String? _error;

  GoogleSignInAccount? get account => _account;
  bool get isSignedIn => _account != null;
  bool get initialized => _initialized;
  bool get signInReady => _pluginInitialized;
  String? get error => _error;
  String get webClientId =>
      _webClientId.isNotEmpty ? _webClientId : _runtimeWebClientId.trim();
  bool get canConfigureWebOAuth =>
      kIsWeb && _webClientId.isEmpty && !_pluginInitialized;
  bool get platformSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  String? get oauthUnavailableMessage {
    if (!platformSupported) {
      return 'Google Sign-In ยังไม่รองรับ Windows/Linux โดยแพ็กเกจที่ใช้ '
          'กรุณาใช้แอปเวอร์ชันเว็บสำหรับการเชื่อมต่อ Google';
    }
    if (kIsWeb && webClientId.isEmpty) {
      return 'ยังไม่ได้ตั้งค่า Google OAuth Client ID สำหรับ Web';
    }
    return null;
  }

  bool get oauthConfigured => oauthUnavailableMessage == null;

  static bool isValidWebClientId(String value) {
    final clientId = value.trim();
    return clientId.length >= 30 &&
        RegExp(
          r'^[0-9]+-[a-zA-Z0-9_-]+\.apps\.googleusercontent\.com$',
        ).hasMatch(clientId);
  }

  Future<void> initialize({String? webClientId}) async {
    if (_initialized) return;
    _runtimeWebClientId = webClientId?.trim() ?? _runtimeWebClientId;
    final unavailableMessage = oauthUnavailableMessage;
    if (unavailableMessage != null) {
      _error = unavailableMessage;
      _initialized = true;
      notifyListeners();
      return;
    }

    await _initializePlugin();
  }

  Future<void> configureWebClientId(String value) async {
    final clientId = value.trim();
    if (!kIsWeb) {
      throw StateError('การตั้งค่า Web OAuth ทำได้จากแอปเวอร์ชันเว็บเท่านั้น');
    }
    if (!isValidWebClientId(clientId)) {
      throw const FormatException(
        'รูปแบบ Google Web OAuth Client ID ไม่ถูกต้อง',
      );
    }
    if (_pluginInitialized) {
      if (clientId == webClientId) return;
      throw StateError('กรุณาโหลดหน้าแอปใหม่ก่อนเปลี่ยน OAuth Client ID');
    }
    _runtimeWebClientId = clientId;
    _initialized = false;
    _error = null;
    notifyListeners();
    await _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    final signIn = GoogleSignIn.instance;
    _subscription ??= signIn.authenticationEvents.listen(
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
      final clientId = switch (defaultTargetPlatform) {
        _ when kIsWeb => webClientId,
        TargetPlatform.iOS => _iosClientId,
        TargetPlatform.macOS => _macosClientId,
        _ => null,
      };
      await signIn.initialize(
        clientId: clientId,
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );
      _pluginInitialized = true;
      _initialized = true;
      _error = null;
      notifyListeners();
    } catch (error) {
      _error = _friendlyError(error);
      _initialized = true;
      notifyListeners();
      return;
    }

    // Do not start a silent/One Tap authentication attempt here. On the web,
    // that can open Google's account verification UI as soon as the app loads.
    // Authentication must only begin after the user presses the Google button.
  }

  Future<void> signIn() async {
    _error = null;
    notifyListeners();
    try {
      final unavailableMessage = oauthUnavailableMessage;
      if (unavailableMessage != null) {
        throw StateError(unavailableMessage);
      }
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
