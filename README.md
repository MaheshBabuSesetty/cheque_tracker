# Sobha Cheque Tracker — Field Collection App

A Flutter app scaffolded with **Clean Architecture**, **SOLID principles**, and **Riverpod** (code-gen style) for state management. Routing uses Flutter's built-in `Navigator` with custom animated transitions — no third-party router. The UI follows the approved "Sobha Field Collection" design (black/gold/cream branding, Playfair Display headings + Poppins body): a field agent signs in, records cheque collections through a 6-step capture flow (vendor, representative + photo, Emirates ID scan, cheque copy, consent, signature), and reviews past collections in a searchable transactions list.

## Architecture

```
lib/
├── core/                    # Cross-cutting, feature-agnostic code
│   ├── constants/           # App-wide constants (names, timeouts, API paths)
│   ├── di/                  # Composition root: every provider lives here
│   ├── error/                # Failure (domain-facing) / Exception (data-facing) types
│   ├── network/               # Dio client, connectivity check, interceptors
│   ├── routing/                # Route names, onGenerateRoute, animated PageRoute
│   ├── theme/                   # Light/dark ThemeData, brand palette, theme mode provider
│   ├── utils/                   # Validators, BuildContext/String extensions, Result type
│   └── widgets/                 # Shared widgets (SobhaWordmark, LabeledTextField, ...)
│
├── features/
│   ├── auth/                    # Sign-in with a field agent ID + password
│   │   ├── data/
│   │   │   ├── datasources/     # AuthRemoteDataSource (Dio, live), AzureAdSsoService (Entra ID OIDC)
│   │   │   ├── models/           # UserModel (extends User, JSON), LoginRequestDto (freezed)
│   │   │   └── repositories/     # AuthRepositoryImpl — the only class that sees both sides
│   │   ├── domain/
│   │   │   ├── entities/          # User — pure Dart, zero Flutter/package imports
│   │   │   ├── repositories/      # AuthRepository — abstract contract
│   │   │   └── usecases/          # LoginUser, LogoutUser, GetCurrentUser
│   │   └── presentation/
│   │       ├── providers/          # Usecase providers + @riverpod AuthNotifier
│   │       └── screens/            # SplashScreen, LoginScreen
│   │
│   └── collection/               # The cheque-collection flow — the app's actual purpose
│       ├── data/
│       │   ├── datasources/       # VendorLocalDataSource, CollectionLocalDataSource, MockEmiratesIdOcrService
│       │   ├── models/             # CollectionRecordModel (extends CollectionRecord, JSON)
│       │   └── repositories/       # VendorRepositoryImpl, CollectionRepositoryImpl
│       ├── domain/
│       │   ├── entities/            # Vendor, CollectionRecord, CollectionDraft, EmiratesIdScan
│       │   ├── repositories/        # VendorRepository, CollectionRepository, EmiratesIdOcrService
│       │   └── usecases/            # GetVendors, GetCollections, SubmitCollection, ScanEmiratesId
│       └── presentation/
│           ├── providers/            # CollectDraftNotifier, Collections, TransactionsFilterNotifier, ...
│           ├── screens/               # MainShellScreen, CollectScreen, TransactionsScreen, CollectionDetailScreen
│           └── widgets/                # StepCard, CaptureTile, SignaturePad, VendorPickerSheet, StatusBadge
│
├── services/                 # App-wide services, not owned by any one feature
│   ├── storage_service.dart       # SharedPreferences-backed key/value store
│   ├── connectivity_service.dart  # Reactive online/offline stream for UI
│   ├── analytics_service.dart     # Event logging (console impl by default)
│   ├── notification_service.dart  # In-app notification broadcast stream
│   └── image_capture_service.dart # Camera capture + persistence into app documents dir
│
└── main.dart
```

### The dependency rule

`presentation → domain ← data`. The `domain` layer (entities, repository interfaces, usecases) never imports Flutter, Dio, or any other package — it's plain Dart. `data` and `presentation` both depend on `domain`, never on each other directly.

### Where SOLID shows up

- **Single Responsibility** — each usecase (`LoginUser`, `SubmitCollection`, `ScanEmiratesId`, ...) does exactly one thing and can be tested alone.
- **Open/Closed** — `AuthRepository`, `EmiratesIdOcrService`, `StorageService`, `AnalyticsService`, `ImageCaptureService` are all abstract contracts; swapping the concrete implementation (e.g. `MockEmiratesIdOcrService` → a real OCR provider) never touches a call site.
- **Liskov Substitution** — any class implementing a repository/service interface (a real one, or a `mocktail` fake in tests) is fully interchangeable wherever the abstraction is used.
- **Interface Segregation** — `NetworkInfo` (a point-in-time connectivity check, for repositories) is kept separate from `ConnectivityService` (a long-lived stream, for UI); `VendorRepository`/`CollectionRepository`/`EmiratesIdOcrService`/`ChequeOcrService` are four separate small interfaces, even though all four live in the same feature, because scanning an ID has nothing to do with scanning a cheque.
- **Dependency Inversion** — providers in `core/di/dependency_injection.dart` depend on the abstract types; the concrete classes are wired in exactly one place.

### State management

Riverpod with code generation (`@riverpod`). `AuthNotifier` models the session as `AsyncValue<User?>`; `CollectDraftNotifier` models the entire 6-step form as one immutable `CollectionDraft` (see `collection_draft.dart` for the step-completion logic, which is pure Dart and unit-tested without touching Riverpod). Widgets `ref.watch` for rebuilds, `ref.read` inside callbacks, and `ref.listen` for one-off side effects (snackbars, navigation, syncing a `TextEditingController` after an OCR auto-fill).

Note: riverpod_generator names the provider for a class by stripping a trailing `Notifier` — `AuthNotifier` → `authProvider`, `CollectDraftNotifier` → `collectDraftProvider`.

### Routing

`core/routing/app_router.dart` exposes a single `onGenerateRoute` wired into `MaterialApp`, plus a global `navigatorKey`. `core/routing/page_transitions.dart` provides `AppPageRoute`, a `PageRouteBuilder` with fade/slide/scale transitions. The auth-guard redirect lives in `SplashScreen`, which awaits the initial `authProvider` resolution before routing to `login` or `home` (`MainShellScreen`). Inside the shell, the Collect/Transactions tabs are an `IndexedStack` driven by a plain `int` notifier (`mainTabIndexProvider`) rather than a nested `Navigator` — neither tab needs its own back stack; drilling into a transaction still goes through a named route (`RouteNames.collectionDetail`, record id passed via `settings.arguments`).

### Remember this device

The "Remember this device" checkbox on `LoginScreen` (default checked) is opt-in persistence, not the only way the session survives at all: `AuthRepositoryImpl.login`/`loginWithSso` always cache the session (every authenticated request reads its token straight from `StorageService`, so the app couldn't function this run without it) and separately persist the checkbox's value via `StorageService.saveRememberDevice`. The decision only bites at the *next* cold start — `AuthRepositoryImpl.getCurrentUser()` (called once per process, from `AuthNotifier.build()`) wipes the cached session and forces the login screen if the stored flag is `false`. A `null` flag (pre-upgrade installs, or a device that's never logged in) is left alone rather than treated as "don't remember."

### Theming

`core/theme/app_theme.dart` builds Material 3 `light`/`dark` `ThemeData` from the brand palette (`AppColors`: ink/gold/cream), with a shared `inputDecorationTheme` so every text field gets the same rounded/filled look. Typography pairs Playfair Display (headings/wordmark) with Poppins (body/UI) via `google_fonts`. `themeMode` is a persisted `@riverpod` notifier (`appThemeModeProvider`); `MaterialApp.themeAnimationDuration/Curve` animates the switch. The splash/login screens are intentionally always black/gold/cream regardless of theme mode — that's brand, not a "dark mode".

### Dependency injection

Riverpod itself is the DI mechanism. `core/di/dependency_injection.dart` is the composition root: datasources → repositories → usecases, each a `Provider` depending on the abstraction above it. `main.dart` only has to override `sharedPreferencesProvider`; everything else resolves lazily from that.

### What's mocked, and how to un-mock it

There's no live backend yet, so a few things are intentionally simulated behind their real interfaces:

- **Auth (password)** — live: `AuthRemoteDataSourceImpl` hits the real `POST /auth/login` on the DEV API.
- **Auth (SSO)** — client-side only: `AzureAdSsoService` runs a real Microsoft Entra ID OIDC sign-in (via `flutter_appauth`) and hands the resulting id token to `POST /auth/sso`, but **that endpoint doesn't exist on the backend yet** — see `AuthRemoteDataSource.loginWithSso`'s doc comment for the expected request/response contract. Until then, and until IT/identity registers a real app registration (`.env`'s `AZURE_AD_*` keys are placeholders — see "SSO (Microsoft Entra ID) setup" below), the "Sign in with Microsoft" button will fail at the token-exchange step.
- **Emirates ID OCR** — `MockEmiratesIdOcrService` simulates scan latency and returns plausible fields. Swap in a real OCR provider behind `EmiratesIdOcrService` the same way.
- **Cheque OCR** — `MockChequeOcrService` simulates scanning a captured cheque copy: it detects a currency (55% AED, 35% USD, 10% something else) and, for AED/USD, a drawee bank, cheque number and amount. Anything other than AED/USD is rejected (`ChequeScan.accepted == false`) — `CollectDraftNotifier` clears the cheque number/amount and blocks step 4 until the agent recaptures. Swap in a real cheque-OCR provider behind `ChequeOcrService` the same way.
- **Collections storage** — `CollectionLocalDataSource` persists locally via `SharedPreferences` only; there is no "push to the web application tracker" network call yet. A real sync step would sit behind `CollectionRepository.submit` without any presentation/domain changes.

## Adding a new feature

1. Create `lib/features/<name>/{data,domain,presentation}` with the same sub-folders as `auth`/`collection`.
2. **Domain first**: write the entity, the repository interface, and the usecases. No imports outside `dart:core`/`equatable`.
3. **Data**: write the model(s) (`extends` the entity, add `fromJson`/`toJson` if it needs to be persisted/serialized — static/local-only data can skip the model and use the entity directly, as `Vendor` does), the datasource(s), and the repository implementation.
4. Wire the new repository (and its datasources) into `core/di/dependency_injection.dart` as providers.
5. **Presentation**: add usecase providers, an `@riverpod` notifier if the feature has async/mutable state, and screens/widgets. Run `dart run build_runner build --delete-conflicting-outputs` after adding any `@riverpod`/`@freezed`/`@JsonSerializable` annotation.
6. Add a route name in `core/routing/route_names.dart` and a case in `core/routing/app_router.dart`'s `onGenerateRoute`.
7. Write a domain test (pure entity logic and/or a usecase with a `mocktail`-mocked repository) — see `test/features/collection/domain/` for the pattern.

## Running

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerate *.g.dart / *.freezed.dart after model/provider changes
flutter run --dart-define-from-file=.env --dart-define=APP_ENV=dev   # or uat / prod
flutter test
```

Environment config (API base URLs for dev/uat/prod) lives in `.env` and is picked at build/run time via `--dart-define=APP_ENV=<dev|uat|prod>` (defaults to `dev` if omitted). The `dev` and `prod` hosts are confirmed live — see the comments in `.env` before relying on `uat`.

Camera capture (representative photo, Emirates ID front/back, cheque copy, voucher, supporting documents) uses an in-app camera screen (`core/widgets/camera/in_app_camera_screen.dart`, via the `camera` package), which needs a real device or a simulator that supports it — `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` are already set in `ios/Runner/Info.plist`, and `android.permission.CAMERA` in the Android manifest.

### SSO (Microsoft Entra ID) setup

The login screen's "Sign in with Microsoft" button (`LoginScreen`/`AuthNotifier.loginWithSso`) is fully wired end-to-end on the client, but needs two things from outside this repo before it actually works:

1. **An Entra ID app registration** (single-tenant, native/public client) with a **"Mobile and desktop applications" platform** redirect URI of:
   ```
   com.sobha.chequetracker://oauthredirect
   ```
   DEV and UAT share one app registration; PROD uses its own separate registration (same tenant). Then fill in the real values in `.env`, replacing the `REPLACE_WITH_*` placeholders:
   ```
   AZURE_AD_TENANT_ID=<tenant id>
   DEV_AZURE_AD_CLIENT_ID=<dev/uat client id>
   UAT_AZURE_AD_CLIENT_ID=<dev/uat client id>
   PROD_AZURE_AD_CLIENT_ID=<prod client id>
   ```
   Public-client app registrations authenticate via Authorization Code + PKCE and don't use a client secret — don't generate or store one for this registration.

   (`*_AZURE_AD_REDIRECT_URI` only needs to change if the app's bundle ID / applicationId ever changes — it's derived from `com.sobha.chequetracker`, already wired into `android/app/build.gradle.kts`'s `appAuthRedirectScheme` placeholder and `ios/Runner/Info.plist`'s `CFBundleURLTypes`.)
2. **A backend `POST /auth/sso` endpoint** that accepts `{ idToken, provider }`, verifies the token against Entra ID's public keys/issuer, and returns the same session shape `POST /auth/login` does. See `AuthRemoteDataSource.loginWithSso`'s doc comment for the exact contract. This endpoint doesn't exist yet — until it does, tapping "Sign in with Microsoft" will complete the real Microsoft sign-in but fail on the token-exchange call.

**Known limitation**: `flutter_appauth` (the OIDC client this uses) is a generic client with no way to participate in Microsoft's proprietary broker handoff. On a device with Microsoft Authenticator or Intune Company Portal installed, if the tenant's Conditional Access policy requires broker-based sign-in for native/mobile apps, `AzureAdSsoService.signIn` hangs indefinitely (no success, no error, no timeout — confirmed via live device testing). This was previously worked around by switching to `msal_auth` (Microsoft's own MSAL SDK wrapper), then reverted back to `flutter_appauth`. If that hang reappears, `msal_auth` is the known fix — see `AzureAdSsoService`'s doc comment and git history around that migration for the exact native setup it needs (Info.plist/entitlements/AndroidManifest changes, a bumped iOS 16+ deployment target, and Android/iOS platform registrations in Entra ID).

Architecture-wise, the whole SSO flow follows the same pattern the rest of the app uses for swappable integrations (`EmiratesIdOcrService`, `ChequeOcrService`, `ImageCaptureService`): `SsoAuthService` is the abstract contract (`domain/repositories/sso_auth_service.dart`), `AzureAdSsoService` (`data/datasources/azure_ad_sso_data_source.dart`) is the one concrete implementation today. Adding a second provider (Google, Okta, ...) means a new class behind that same interface, not a change to `AuthRepository`/`AuthNotifier`/`LoginScreen`.

### Migrating the OAuth redirect to verified App Links (pentest V-06)

The mobile pentest report flagged the redirect above (`com.sobha.chequetracker://oauthredirect`) as a custom URI scheme, which neither Android nor iOS treats as exclusive to this app — another installed app could register the same scheme and receive the redirect. PKCE (already implemented) stops that from being exploitable, but a verified [Android App Link](https://developer.android.com/training/app-links/verify-android-applinks) / [iOS Universal Link](https://developer.apple.com/ios/universal-links/) closes the gap properly. Everything client-side is scaffolded and wired, and inert until the two external pieces below exist per environment — do not flip a `.env` line before both are done for that environment, or Microsoft sign-in will stop completing for it.

The hosts already used for the API — `chqtrk-api-dev.sobhaapps.com`, `chqtrk-api-uat.sobhaapps.com`, `chequetracker-api.sobhaapps.com` (prod) — are the chosen redirect hosts:

- **Android** — a single `autoVerify` intent-filter is declared on `RedirectUriReceiverActivity` in `AndroidManifest.xml`, targeting the `${oauthRedirectHost}` manifest placeholder. `android/app/build.gradle.kts`'s `resolveOauthRedirectHost()` resolves that placeholder from the same `APP_ENV` dart-define the Dart side already reads (`flutter build apk --dart-define-from-file=.env --dart-define=APP_ENV=uat`, exactly as documented above — no extra build flag needed), so a given build's manifest only ever contains the one host it was actually built for. This was tightened after the pentest's own V-14 evidence showed a decompiled APK listing all three hosts (dev/uat/prod) at once; each environment's build now only reveals its own API host to anyone inspecting that build.
- **iOS** — `ios/Runner/Runner.entitlements` declares `applinks:` for all three hosts and is wired into `CODE_SIGN_ENTITLEMENTS` for all three build configurations (Debug/Release/Profile) of the `Runner` target. Unlike Android, this hasn't been narrowed to the active environment yet — iOS wasn't in the pentest's scope, and per-build-configuration entitlements (rather than a single dart-define-driven placeholder) would need Debug/Release/Profile to line up with dev/uat/prod, which they don't today.

Two things outside this repo still need to happen per host before any of this is live:

1. **Publish the platform verification file** at `https://<host>/.well-known/`:
   - Android: `assetlinks.json` — `android/app/assetlinks.json.template` has the exact JSON (identical content for all three hosts, since all three builds are signed by the same keystore). It needs the app's SHA-256 signing certificate fingerprint(s), obtainable via:
     ```
     keytool -list -v -keystore <your-release-keystore> -alias <key-alias>
     ```
     (one fingerprint per keystore that signs a build reaching real devices — typically release, and debug too if App Links need to work on debug builds).
   - iOS: `apple-app-site-association` (no file extension, `Content-Type: application/json`) — `ios/Runner/apple-app-site-association.template` has the exact JSON, usable as-is (Team ID + bundle ID don't vary per environment, so there's no placeholder to fill in).
2. **Register each HTTPS URL** (`https://chqtrk-api-dev.sobhaapps.com/oauthredirect`, `https://chqtrk-api-uat.sobhaapps.com/oauthredirect`, `https://chequetracker-api.sobhaapps.com/oauthredirect`) as additional redirect URIs on the Entra ID app registration's "Mobile and desktop applications" platform, alongside the existing custom-scheme one.

Once both are live for a given environment, flip **only that environment's** line in `.env` — `DEV_`/`UAT_`/`PROD_AZURE_AD_REDIRECT_URI` (`AzureAdConfig.redirectUri` already selects between them the same way `AppEnvironment.apiBaseUrl` does) — from the custom scheme to that host's `https://.../oauthredirect` URL. Cut over per-environment independently (e.g. UAT first) rather than all three at once, since each depends on its own host's verification file being correct.

Until an environment's cutover is done, that build keeps using the custom scheme as its active `redirectUri` — the App Link / Universal Link declarations above are additional, not a replacement, so nothing here can break the current working sign-in flow for an environment that hasn't cut over yet.

### Certificate pinning (pentest V-13)

The mobile pentest report flagged that the client validates TLS against the OS's built-in trust store only, with no certificate pinning — a defense-in-depth gap, not a live exploit (a working interception still needs a compromised device or a trusted-CA install). Pinning is scaffolded in `lib/core/network/certificate_pinning.dart` and wired into both `DioClient` and `UnauthenticatedDioClient`, but **inert by default**: `configureCertificatePinning` is a no-op until `DEV_`/`UAT_`/`PROD_CERT_PINS` in `.env` are filled in for the environment being built, so nothing here changes today's behaviour or risks locking a build out of its own API before real fingerprints are known.

To enable it for an environment, get that host's certificate SHA-256 fingerprint:

```bash
openssl s_client -connect chqtrk-api-uat.sobhaapps.com:443 -servername chqtrk-api-uat.sobhaapps.com < /dev/null 2>/dev/null \
  | openssl x509 -outform der \
  | openssl dgst -sha256 -binary | openssl enc -base64
```

and set the matching `.env` line to a comma-separated list of at least two fingerprints — the current leaf plus the certificate that will replace it (or a backup/intermediate), so a routine renewal on the API side doesn't brick connectivity before an app update carrying the new pin can ship:

```
UAT_CERT_PINS=<current-leaf-sha256>,<next-or-backup-sha256>
```

Pinning validates the full certificate (not just its public key), so every fingerprint in the list needs updating whenever the corresponding certificate is renewed — track the API's renewal/rotation schedule and ship an app update with the new pin ahead of it.

### Removed the unused RECORD_AUDIO permission (pentest V-16)

The `camera` plugin's own `AndroidManifest.xml` declares `RECORD_AUDIO` unconditionally for its video-recording API. This app only ever opens the camera controller with `enableAudio: false` (`in_app_camera_screen.dart`) to capture still photos (collector, cheque, Emirates ID) — it never records video or audio. `android/app/src/main/AndroidManifest.xml` now strips the merged permission with `tools:node="remove"`, so it no longer appears in the built APK or the Play Store listing.

## Release build

Bump `version:` in `pubspec.yaml` first (`x.y.z+buildNumber`) — Android's version code and iOS's build number both come from the `+buildNumber` suffix.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
```

**Android** — needs a signing config once: copy `android/key.properties.example` to `android/key.properties` (git-ignored) and fill in a real keystore's `storePassword`/`keyPassword`/`keyAlias`/`storeFile`. Then:

```bash
flutter build appbundle --release --dart-define-from-file=.env --dart-define=APP_ENV=prod                    # Play Store upload
flutter build apk --release --dart-define-from-file=.env --dart-define=APP_ENV=prod                          # single universal APK, direct install
flutter build apk --release --split-per-abi --dart-define-from-file=.env --dart-define=APP_ENV=prod           # per-ABI APKs, direct install
```

`--split-per-abi` produces one smaller APK per CPU architecture (`app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk`) under `build/app/outputs/flutter-apk/` instead of one large universal APK bundling all of them — install whichever matches the test device. The `appbundle` (`.aab`) doesn't need this flag: Play Store already splits it per-device automatically.

**iOS** — code signing is `Automatic` in the Xcode project already; make sure the signing team is set in Xcode (or via `xcodebuild` args) before archiving:

```bash
flutter build ipa --release --dart-define-from-file=.env --dart-define=APP_ENV=prod
```

Swap `APP_ENV=prod` for `uat` to ship a staging build instead. As noted in `.env`, only the `dev` and `prod` hosts are confirmed live — verify the `UAT_API_BASE_URL` hostname before relying on it.

### A note on dependency versions

This project pins `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` to the **3.x/4.x** line and `freezed`/`freezed_annotation` to **3.x**, rather than the 2.x versions originally drafted. The 2.x `riverpod_generator` pulls in `riverpod_analyzer_utils` → `custom_lint_core` → `analyzer_plugin`, and that chain does not compile against the `analyzer` version this Flutter SDK resolves — `dart run build_runner build` fails before it ever gets to run a builder. The 3.x/4.x line dropped that dependency, which is the actual fix (as opposed to pinning `analyzer` down, which just relocates the same incompatibility).
