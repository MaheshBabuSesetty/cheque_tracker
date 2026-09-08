import 'dart:async';

import 'package:flutter/foundation.dart';
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
///
/// SCOPES: every entry in [_scopes] must be a scope Entra can actually
/// resolve. An unqualified scope is looked up against Microsoft Graph, so a
/// bare resource name (`'api'`) fails with AADSTS650053 *after* the agent
/// has already signed in — Entra renders its error page inside the web
/// session and never redirects back, so `authorizeAndExchangeCode` simply
/// never completes. To request a token for this app's own backend, use the
/// fully-qualified form (`api://<client-id>/<scope>` or
/// `<client-id>/.default`) and expose that scope on the app registration.
///
/// One page in this flow is not an error and cannot be skipped from here:
/// "Are you trying to sign in to `<app registration name>`?", which Entra
/// shows because [AzureAdConfig.redirectUri] is a custom scheme it can't
/// cryptographically attribute to a verified app. The agent has to tap
/// Continue. If that page ever renders unstyled with both buttons greyed
/// out, its styles/scripts (served from `aadcdn.msftauth.net`) didn't
/// load — a browser or network fault on the device, not something this
/// client can work around.
///
/// The one thing this client structurally cannot do is Microsoft's
/// proprietary broker handoff to Authenticator/Company Portal — that is not
/// OIDC, so no generic OIDC client speaks it. It only matters if the tenant
/// enforces a Conditional Access policy requiring an approved client app or
/// an app protection policy; absent such a policy (none observed here) the
/// plain web flow below is the complete, supported path. If one is ever
/// added, the fix is a tenant-side exclusion for this app registration, or
/// Microsoft's own MSAL SDK — not a workaround at this layer.
class AzureAdSsoService implements SsoAuthService {
  const AzureAdSsoService(this._appAuth);

  final FlutterAppAuth _appAuth;

  static const _provider = 'azuread';
  static const _scopes = ['openid', 'profile', 'email', 'offline_access'];

  /// Hard ceiling on the whole authorize-and-exchange round trip. Any flow
  /// that ends on an Entra error page instead of a redirect (see SCOPES
  /// above) never settles on its own, so without this the sign-in button
  /// spins forever with nothing logged. Short enough that a stuck flow
  /// reports itself, but sized for the *whole* human round trip, which is
  /// longer than it looks: password, an MFA prompt, and then the "Are you
  /// trying to sign in to...?" confirmation tap described above. At the
  /// former 120s a slow-but-succeeding sign-in could trip this and have its
  /// result discarded, which reads to the agent exactly like a failure.
  static const _timeout = Duration(minutes: 5);

  /// An *ephemeral* session (rather than the default
  /// [ExternalUserAgent.asWebAuthenticationSession]) doesn't share Safari's
  /// cookie jar, so it never picks up an existing Microsoft web session —
  /// the agent retypes their credentials on every sign-in. That is a real
  /// cost, taken deliberately: an isolated jar also can't pick up a
  /// device-registration/PRT cookie, which keeps this flow on the plain web
  /// path. Switch back to the default if seamless re-login matters more.
  /// iOS/macOS only — ignored on Android (the enum is documented as
  /// iOS/macOS-only), which has no equivalent distinction: a Chrome Custom
  /// Tab always shares Chrome's cookie jar. The nearest Android lever is
  /// `promptValues: [Prompt.login]` on the request below, deliberately not
  /// set — it would force every agent to retype credentials on every
  /// sign-in, on both platforms.
  static const _externalUserAgent = ExternalUserAgent.ephemeralAsWebAuthenticationSession;

  @override
  Future<SsoIdentity?> signIn() async {
    if (kDebugMode) {
      debugPrint(
        'Microsoft SSO: launching sign-in — clientId=${AzureAdConfig.clientId} '
        'redirectUri=${AzureAdConfig.redirectUri} discoveryUrl=${AzureAdConfig.discoveryUrl}',
      );
    }
    try {
      final result = await _appAuth
          .authorizeAndExchangeCode(
            AuthorizationTokenRequest(
              AzureAdConfig.clientId,
              AzureAdConfig.redirectUri,
              discoveryUrl: AzureAdConfig.discoveryUrl,
              scopes: _scopes,
              externalUserAgent: _externalUserAgent,
            ),
          )
          .timeout(_timeout);
      final idToken = result.idToken;
      if (kDebugMode) {
        // Never the raw token values themselves — an id/access/refresh
        // token is a bearer credential, not something to leave sitting in
        // device logs even in debug builds.
        debugPrint(
          'Microsoft SSO: authorizeAndExchangeCode returned — '
          'idToken=${idToken != null ? "${idToken.length} chars" : "null"} '
          'accessToken=${result.accessToken != null} '
          'refreshToken=${result.refreshToken != null} '
          'accessTokenExpiry=${result.accessTokenExpirationDateTime}',
        );
      }
      if (idToken == null) throw const AuthException('Microsoft sign-in did not return an identity token.');
      return (idToken: idToken, provider: _provider);
    } on FlutterAppAuthUserCancelledException {
      if (kDebugMode) debugPrint('Microsoft SSO: agent cancelled the sign-in UI.');
      return null;
    } on TimeoutException {
      // Microsoft's page never redirected back to us — almost always an
      // Entra-side rejection rendered as a web page (bad scope, unregistered
      // redirect URI, a CA policy demanding a broker). Nothing here can
      // recover it; say so plainly rather than spinning forever. The
      // debugPrint above is where the real cause shows up.
      if (kDebugMode) debugPrint('Microsoft SSO: timed out after $_timeout with no redirect back to the app.');
      throw const AuthException(
        "Microsoft sign-in didn't complete. If this device is managed by your "
        'company, its sign-in policy may not be supported here yet — please use '
        'your username and password, and report this to IT.',
      );
    } on FlutterAppAuthPlatformException catch (e) {
      // The plugin's own subclass of [PlatformException], carrying the
      // underlying AppAuth SDK's structured error — which is where Entra's
      // `error`/`error_description` (the AADSTS code saying *why* it
      // refused) actually lands. The bare `on PlatformException` clause
      // below would still match this, since it extends it, but would throw
      // all of that detail away — so this has to come first.
      final details = e.platformErrorDetails;
      if (kDebugMode) debugPrint('Microsoft SSO: FlutterAppAuthPlatformException code=${e.code} $details');
      // Not `details.errorDescription` as the user-facing message: Entra's
      // description is a multi-line AADSTS block, and this string renders
      // as 11px inline text under LoginScreen's password field. The short
      // `error` code is the part an agent can read out to IT; the full
      // block is in the debugPrint above.
      final error = details.error;
      throw AuthException(
        error == null
            ? 'Microsoft sign-in failed.'
            : 'Microsoft sign-in failed ($error). Please use your username '
                  'and password, and report this to IT.',
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('Microsoft SSO: PlatformException code=${e.code} message=${e.message} details=${e.details}');
      }
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
