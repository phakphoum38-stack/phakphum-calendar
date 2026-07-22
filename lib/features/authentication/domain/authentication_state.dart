import 'google_user.dart';

enum AuthenticationStatus {
  uninitialized,
  signedOut,
  signingIn,
  signedIn,
  failure,
}

class AuthenticationState {
  const AuthenticationState({
    required this.status,
    this.user,
    this.message,
  });

  const AuthenticationState.uninitialized()
      : this(status: AuthenticationStatus.uninitialized);

  final AuthenticationStatus status;
  final GoogleUser? user;
  final String? message;
}
