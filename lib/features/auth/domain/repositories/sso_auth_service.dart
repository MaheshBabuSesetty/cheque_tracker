/// The identity token an SSO sign-in produced, handed to the backend for
/// verification/exchange — see `AuthRemoteDataSource.loginWithSso`.
typedef SsoIdentity = ({String idToken, String provider});

/// Abstraction over a third-party identity provider's native sign-in SDK
/// (Microsoft Entra ID today; [AuthRepositoryImpl] never imports the
/// concrete `flutter_appauth`-backed implementation directly — Dependency
/// Inversion, same as [EmiratesIdOcrService]/[ChequeOcrService]). Swapping
/// or adding a provider (Google, Okta, ...) means a new implementation of
/// this contract, not a change to the repository or presentation layer.
abstract class SsoAuthService {
  /// Runs the provider's hosted sign-in UI and returns the resulting
  /// identity token, or `null` if the agent cancelled/dismissed it.
  Future<SsoIdentity?> signIn();

  /// Clears any session the provider's SDK itself holds (separate from
  /// this app's own token cache, which [AuthLocalDataSource] owns).
  Future<void> signOut();
}
