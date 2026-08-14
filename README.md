# Sobha Cheque Tracker — Field Collection App

A Flutter app scaffolded with **Clean Architecture**, **SOLID principles**, and **Riverpod** (code-gen style) for state management. Routing uses Flutter's built-in `Navigator` with custom animated transitions — no third-party router. The UI follows the approved "Sobha Field Collection" design (black/gold/cream branding, Playfair Display headings + Poppins body): a field agent signs in, records cheque collections through a 6-step capture flow (vendor, representative + photo, Emirates ID scan, cheque copy, consent, signature), and reviews past collections in a searchable transactions list.

## Architecture

```
lib/
├── core/                    # Cross-cutting, feature-agnostic code
│   ├── constants/           # App-wide constants (names, timeouts, API paths, demo creds)
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
│   │   │   ├── datasources/     # AuthRemoteDataSource (Dio, unused for now) + MockAuthRemoteDataSource (wired in)
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

### Theming

`core/theme/app_theme.dart` builds Material 3 `light`/`dark` `ThemeData` from the brand palette (`AppColors`: ink/gold/cream), with a shared `inputDecorationTheme` so every text field gets the same rounded/filled look. Typography pairs Playfair Display (headings/wordmark) with Poppins (body/UI) via `google_fonts`. `themeMode` is a persisted `@riverpod` notifier (`appThemeModeProvider`); `MaterialApp.themeAnimationDuration/Curve` animates the switch. The splash/login screens are intentionally always black/gold/cream regardless of theme mode — that's brand, not a "dark mode".

### Dependency injection

Riverpod itself is the DI mechanism. `core/di/dependency_injection.dart` is the composition root: datasources → repositories → usecases, each a `Provider` depending on the abstraction above it. `main.dart` only has to override `sharedPreferencesProvider`; everything else resolves lazily from that.

### What's mocked, and how to un-mock it

There's no live backend yet, so a few things are intentionally simulated behind their real interfaces:

- **Auth** — `MockAuthRemoteDataSource` accepts the demo credentials (`AppConstants.demoAgentId` / `demoAgentPassword`, shown on the login screen's "Use demo agent" link). The real Dio-backed `AuthRemoteDataSourceImpl` already exists; swapping it in is a one-line change in `dependency_injection.dart`.
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
flutter run
flutter test
```

Camera capture (representative photo, Emirates ID front/back, cheque copy) uses `image_picker`, which needs a real device or a simulator that supports the camera intent — `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription` are already set in `ios/Runner/Info.plist`, and `android.permission.CAMERA` in the Android manifest.

### A note on dependency versions

This project pins `flutter_riverpod`/`riverpod_annotation`/`riverpod_generator` to the **3.x/4.x** line and `freezed`/`freezed_annotation` to **3.x**, rather than the 2.x versions originally drafted. The 2.x `riverpod_generator` pulls in `riverpod_analyzer_utils` → `custom_lint_core` → `analyzer_plugin`, and that chain does not compile against the `analyzer` version this Flutter SDK resolves — `dart run build_runner build` fails before it ever gets to run a builder. The 3.x/4.x line dropped that dependency, which is the actual fix (as opposed to pinning `analyzer` down, which just relocates the same incompatibility).
