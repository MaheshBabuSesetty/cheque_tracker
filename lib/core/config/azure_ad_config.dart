/// Build-time Microsoft Entra ID (Azure AD) config for SSO login — same
/// `--dart-define-from-file=.env` mechanism as [AppEnvironment], but a
/// single app registration shared across dev/UAT/prod rather than one
/// value per environment (see `.env`'s comment on why).
///
/// The three defaults below are placeholders, not real Entra ID values —
/// SSO sign-in will fail until IT/identity registers a native-app
/// registration and `.env` is updated with the real tenant/client IDs.
class AzureAdConfig {
  const AzureAdConfig._();

  static const String tenantId = String.fromEnvironment('AZURE_AD_TENANT_ID', defaultValue: 'REPLACE_WITH_TENANT_ID');

  static const String clientId = String.fromEnvironment('AZURE_AD_CLIENT_ID', defaultValue: 'REPLACE_WITH_CLIENT_ID');

  static const String redirectUri = String.fromEnvironment(
    'AZURE_AD_REDIRECT_URI',
    defaultValue: 'com.latinem.cheque_tracker://oauthredirect',
  );

  static String get discoveryUrl => 'https://login.microsoftonline.com/$tenantId/v2.0/.well-known/openid-configuration';

  static bool get isConfigured => tenantId != 'REPLACE_WITH_TENANT_ID' && clientId != 'REPLACE_WITH_CLIENT_ID';
}
