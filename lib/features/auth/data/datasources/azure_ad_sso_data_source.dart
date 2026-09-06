import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../../../core/config/azure_ad_config.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/sso_auth_service.dart';

/// Microsoft Entra ID (Azure AD) implementation of [SsoAuthService], via
/// the OIDC authorization-code-with-PKCE flow ([FlutterAppAuth] drives the
/// native browser/ASWebAuthenticationSession UI — no password ever passes
/// through this app). Returns the OIDC `id_token`; the backend is the one
/// that verifies its signature/claims against Entra ID and issues this
/// app's own session, exactly like a password [AuthRemoteDataSource.login]
/// does — see `loginWithSso`'s doc comment.
class AzureAdSsoService implements SsoAuthService {
  const AzureAdSsoService(this._appAuth);

  final FlutterAppAuth _appAuth;

  static const _provider = 'azuread';
  static const _scopes = ['openid', 'profile', 'email', 'offline_access'];

  @override
  Future<SsoIdentity?> signIn() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AzureAdConfig.clientId,
          AzureAdConfig.redirectUri,
          discoveryUrl: AzureAdConfig.discoveryUrl,
          scopes: _scopes,
        ),
      );
      final idToken = result.idToken;
      if (idToken == null) throw const AuthException('Microsoft sign-in did not return an identity token.');
      return (idToken: idToken, provider: _provider);
    } on FlutterAppAuthUserCancelledException {
      return null;
    } on PlatformException catch (e) {
      throw AuthException(e.message ?? 'Microsoft sign-in failed.');
    }
  }

  @override
  Future<void> signOut() async {
    // No local Entra ID session to tear down: this app only ever performs
    // the one-shot authorization-code flow above, and doesn't hold a
    // silent-refresh session via the provider's own SDK — the app's own
    // (already-cleared) token pair is the only session that existed.
  }
}
