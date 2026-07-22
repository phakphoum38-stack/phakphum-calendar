import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/google/google_scopes.dart';
import '../domain/authentication_service.dart';
import '../domain/google_user.dart';

class GoogleAuthenticationService implements AuthenticationService {
  GoogleAuthenticationService({
    GoogleSignIn? googleSignIn,
    this.clientId,
    this.serverClientId,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  final String? clientId;
  final String? serverClientId;

  bool _initialized = false;

  GoogleSignInAccount? _currentAccount;

  GoogleSignInAccount? get currentAccount => _currentAccount;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  @override
  Future<GoogleUser?> restoreSession() async {
    await initialize();

    final future = _googleSignIn.attemptLightweightAuthentication(
      reportAllExceptions: false,
    );

    if (future == null) {
      return null;
    }

    final account = await future;
    _currentAccount = account;
    return account == null ? null : _toDomain(account);
  }

  @override
  Future<GoogleUser> signIn() async {
    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Interactive Google Sign-In is not available through this flow '
        'on the current platform.',
      );
    }

    final account = await _googleSignIn.authenticate(
      scopeHint: GoogleScopes.required,
    );

    await account.authorizationClient.authorizeScopes(GoogleScopes.required);

    _currentAccount = account;
    return _toDomain(account);
  }

  @override
  Future<void> signOut() async {
    await initialize();
    await _googleSignIn.signOut();
    _currentAccount = null;
  }

  @override
  Future<void> disconnect() async {
    await initialize();
    await _googleSignIn.disconnect();
    _currentAccount = null;
  }

  GoogleUser _toDomain(GoogleSignInAccount account) {
    return GoogleUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}
