import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_appauth/flutter_appauth.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/azure_ad_sso_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/repositories/sso_auth_service.dart';
import '../../features/collection/data/datasources/collection_remote_data_source.dart';
import '../../features/collection/data/datasources/mlkit_cheque_ocr_service.dart';
import '../../features/collection/data/datasources/mlkit_emirates_id_ocr_service.dart';
import '../../features/collection/data/datasources/vendor_local_data_source.dart';
import '../../features/collection/data/datasources/vendor_remote_data_source.dart';
import '../../features/collection/data/repositories/collection_repository_impl.dart';
import '../../features/collection/data/repositories/vendor_repository_impl.dart';
import '../../features/collection/domain/repositories/cheque_ocr_service.dart';
import '../../features/collection/domain/repositories/collection_repository.dart';
import '../../features/collection/domain/repositories/emirates_id_ocr_service.dart';
import '../../features/collection/domain/repositories/vendor_repository.dart';
import '../../features/cheques/data/datasources/cheque_remote_data_source.dart';
import '../../features/cheques/data/repositories/cheque_repository_impl.dart';
import '../../features/cheques/domain/repositories/cheque_repository.dart';
import '../../services/analytics_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/image_capture_service.dart';
import '../routing/app_router.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/version_check_service.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';
import '../network/token_refresh_client.dart';
import '../network/unauthenticated_dio_client.dart';
import '../session/session_events.dart';

/// Composition root: every cross-cutting dependency (services, network
/// client, and feature repositories) is declared exactly once here as a
/// provider. Feature-level providers (usecases, notifiers) depend on these
/// abstractions, never on the concrete classes directly — that indirection
/// is what lets `ProviderScope(overrides: [...])` swap in fakes for tests
/// or a different environment (dev/staging/prod) in `main.dart`.
///
/// [sharedPreferencesProvider] is overridden in `main.dart` with the
/// resolved instance obtained during app bootstrap, since acquiring it is
/// async and providers must be created synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart before runApp()',
  );
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    // Explicit rather than the plugin's default: routes through Jetpack's
    // EncryptedSharedPreferences (AES-256-GCM-backed) instead of the
    // plugin's legacy per-key Keystore encryption. Both are hardware-backed
    // and secure either way — this is a hardening upgrade, not a fix for a
    // real gap (found during a security review).
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return SecureStorageService(ref.watch(secureStorageProvider), ref.watch(sharedPreferencesProvider));
});

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityPlusService(ref.watch(connectivityProvider));
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl(ref.watch(connectivityProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return const ConsoleAnalyticsService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = InAppNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

// A deliberately separate, bare Dio — NOT `unauthenticatedDioClientProvider`
// — because that client now carries certificate pinning (pentest V-13) for
// this app's own API host, and Dio resolves an absolute URL (as
// `LoadlyVersionCheckService` passes for the loadly.io share page) without
// going through `baseUrl`. Sharing the pinned client here previously meant
// every version check to loadly.io was silently rejected the moment pins
// went live for an environment, since loadly.io's certificate can never
// match a fingerprint pinned to the API host — found during a security
// review, fixed by giving this its own unpinned client instead.
final versionCheckServiceProvider = Provider<VersionCheckService>((ref) {
  return LoadlyVersionCheckService(Dio());
});

// Login/refresh/logout never carry (or need) the bearer token, and must
// never trigger `AuthInterceptor`'s refresh-on-401 logic — they run on this
// separate, interceptor-free client instead. Also carries certificate
// pinning (pentest V-13) for this app's own API host — see
// `versionCheckServiceProvider` above for why the loadly.io version check
// deliberately does NOT share this client.
final unauthenticatedDioClientProvider = Provider<Dio>((ref) {
  return UnauthenticatedDioClient().dio;
});

final tokenRefreshClientProvider = Provider<TokenRefreshClient>((ref) {
  return TokenRefreshClient(ref.watch(unauthenticatedDioClientProvider));
});

final dioClientProvider = Provider<Dio>((ref) {
  return DioClient(
    ref.watch(storageServiceProvider),
    ref.watch(tokenRefreshClientProvider),
    ref.watch(sessionEventsProvider),
  ).dio;
});

// --- Auth feature wiring -----------------------------------------------
//
// Kept in the composition root rather than the feature folder because the
// repository is a cross-layer seam: presentation must depend on the
// `AuthRepository` abstraction, and this is the one place allowed to know
// about both the abstraction and its concrete implementation.

// Always the real Dio-backed implementation — auth hits the live DEV API
// (see `AppEnvironment`) rather than the local `MockAuthRemoteDataSource`
// that used to stand in for debug builds.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    unauthenticatedDio: ref.watch(unauthenticatedDioClientProvider),
    dio: ref.watch(dioClientProvider),
  );
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(storageServiceProvider));
});

final flutterAppAuthProvider = Provider<FlutterAppAuth>((ref) => const FlutterAppAuth());

final ssoAuthServiceProvider = Provider<SsoAuthService>((ref) {
  return AzureAdSsoService(ref.watch(flutterAppAuthProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    ssoAuthService: ref.watch(ssoAuthServiceProvider),
  );
});

// --- Collection feature wiring ------------------------------------------

final imageCaptureServiceProvider = Provider<ImageCaptureService>((ref) {
  return DeviceImageCaptureService(navigatorKey);
});

// `GET /vendors/available-for-collection` is VRM-only.
final vendorRemoteDataSourceProvider = Provider<VendorRemoteDataSource>((ref) {
  return VendorRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final vendorLocalDataSourceProvider = Provider<VendorLocalDataSource>((ref) {
  return VendorLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl(ref.watch(vendorRemoteDataSourceProvider), ref.watch(vendorLocalDataSourceProvider));
});

// --- Cheques feature wiring ---------------------------------------------
//
final chequeRemoteDataSourceProvider = Provider<ChequeRemoteDataSource>((ref) {
  return ChequeRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final chequeRepositoryProvider = Provider<ChequeRepository>((ref) {
  return ChequeRepositoryImpl(ref.watch(chequeRemoteDataSourceProvider));
});

final collectionRemoteDataSourceProvider = Provider<CollectionRemoteDataSource>((ref) {
  return CollectionRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(ref.watch(collectionRemoteDataSourceProvider));
});

// Shared between both OCR services below — each `scan()` call is keyed by
// its own instance id under the hood, so one on-device recognizer can
// safely serve Emirates ID and cheque scans without interfering.
final textRecognizerProvider = Provider<TextRecognizer>((ref) {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  ref.onDispose(recognizer.close);
  return recognizer;
});

final emiratesIdOcrServiceProvider = Provider<EmiratesIdOcrService>((ref) {
  return MlKitEmiratesIdOcrService(ref.watch(textRecognizerProvider));
});

final chequeOcrServiceProvider = Provider<ChequeOcrService>((ref) {
  return MlKitChequeOcrService(ref.watch(textRecognizerProvider));
});
