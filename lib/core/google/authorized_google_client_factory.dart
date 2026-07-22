import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class AuthorizedGoogleClientFactory {
  const AuthorizedGoogleClientFactory();

  Future<auth.AuthClient> create({
    required GoogleSignInAccount account,
    required List<String> scopes,
    bool allowInteractiveAuthorization = true,
  }) async {
    GoogleSignInClientAuthorization? authorization = await account
        .authorizationClient
        .authorizationForScopes(scopes);

    if (authorization == null && allowInteractiveAuthorization) {
      authorization = await account.authorizationClient.authorizeScopes(scopes);
    }

    if (authorization == null) {
      throw StateError(
        'Google authorization is missing for the required scopes.',
      );
    }

    return authorization.authClient(scopes: scopes);
  }
}
