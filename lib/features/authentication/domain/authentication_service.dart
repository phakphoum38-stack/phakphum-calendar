import 'google_user.dart';

abstract interface class AuthenticationService {
  Future<void> initialize();

  Future<GoogleUser?> restoreSession();

  Future<GoogleUser> signIn();

  Future<void> signOut();

  Future<void> disconnect();
}
