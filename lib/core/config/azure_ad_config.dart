import 'app_environment.dart';

/// Build-time Microsoft Entra ID (Azure AD) config for SSO login — same
/// `--dart-define-from-file=.env` mechanism as [AppEnvironment]. `tenantId`
/// is shared across dev/UAT/prod (one tenant, see `.env`'s comment), but
/// [clientId] is per-environment like [AppEnvironment.apiBaseUrl]: DEV/UAT
/// share one app registration, PROD has its own separate one. [redirectUri]
/// is also per-environment because each environment's App Link cutover
/// (pentest V-06 — see README) happens independently, on its own timeline,
/// as that environment's `assetlinks.json` / `apple-app-site-association`
/// go live.
///
/// `tenantId`/`clientId` default to placeholders below only if `.env` isn't
/// passed via `--dart-define-from-file` — see [isConfigured].
class AzureAdConfig {
  const AzureAdConfig._();

  static const String tenantId = String.fromEnvironment(
    'AZURE_AD_TENANT_ID',
    defaultValue: 'REPLACE_WITH_TENANT_ID',
  );

  static const String _devClientId = String.fromEnvironment(
    'DEV_AZURE_AD_CLIENT_ID',
    defaultValue: 'REPLACE_WITH_CLIENT_ID',
  );
  static const String _uatClientId = String.fromEnvironment(
    'UAT_AZURE_AD_CLIENT_ID',
    defaultValue: 'REPLACE_WITH_CLIENT_ID',
  );
  static const String _prodClientId = String.fromEnvironment(
    'PROD_AZURE_AD_CLIENT_ID',
    defaultValue: 'REPLACE_WITH_CLIENT_ID',
  );

  static const String clientId = AppEnvironment.name == 'prod'
      ? _prodClientId
      : (AppEnvironment.name == 'uat' ? _uatClientId : _devClientId);

  static const String _devRedirectUri = String.fromEnvironment(
    'DEV_AZURE_AD_REDIRECT_URI',
    defaultValue: 'com.sobha.chequetracker://oauthredirect',
  );
  static const String _uatRedirectUri = String.fromEnvironment(
    'UAT_AZURE_AD_REDIRECT_URI',
    defaultValue: 'com.sobha.chequetracker://oauthredirect',
  );
  static const String _prodRedirectUri = String.fromEnvironment(
    'PROD_AZURE_AD_REDIRECT_URI',
    defaultValue: 'com.sobha.chequetracker://oauthredirect',
  );

  static const String redirectUri = AppEnvironment.name == 'prod'
      ? _prodRedirectUri
      : (AppEnvironment.name == 'uat' ? _uatRedirectUri : _devRedirectUri);

  static String get discoveryUrl =>
      'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration';

  static bool get isConfigured =>
      tenantId != 'REPLACE_WITH_TENANT_ID' &&
      clientId != 'REPLACE_WITH_CLIENT_ID';
}
