import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/mock_auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/collection/data/datasources/collection_local_data_source.dart';
import '../../features/collection/data/datasources/mlkit_cheque_ocr_service.dart';
import '../../features/collection/data/datasources/mlkit_emirates_id_ocr_service.dart';
import '../../features/collection/data/datasources/vendor_local_data_source.dart';
import '../../features/collection/data/repositories/collection_repository_impl.dart';
import '../../features/collection/data/repositories/vendor_repository_impl.dart';
import '../../features/collection/domain/repositories/cheque_ocr_service.dart';
import '../../features/collection/domain/repositories/collection_repository.dart';
import '../../features/collection/domain/repositories/emirates_id_ocr_service.dart';
import '../../features/collection/domain/repositories/vendor_repository.dart';
import '../../services/analytics_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/image_capture_service.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/network_info.dart';

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

final storageServiceProvider = Provider<StorageService>((ref) {
  return SharedPreferencesStorageService(ref.watch(sharedPreferencesProvider));
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

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(ref.watch(storageServiceProvider));
});

final dioClientProvider = Provider<Dio>((ref) {
  return DioClient(ref.watch(authInterceptorProvider)).dio;
});

// --- Auth feature wiring -----------------------------------------------
//
// Kept in the composition root rather than the feature folder because the
// repository is a cross-layer seam: presentation must depend on the
// `AuthRepository` abstraction, and this is the one place allowed to know
// about both the abstraction and its concrete implementation.

// There is no live auth backend yet, so `MockAuthRemoteDataSource` (accepts
// the demo agent credentials) is wired in instead of the Dio-backed
// `AuthRemoteDataSourceImpl`. Swapping to the real one when a backend
// exists is exactly this one line — nothing above `data/` changes.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return MockAuthRemoteDataSource();
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSourceImpl(ref.watch(storageServiceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});

// --- Collection feature wiring ------------------------------------------

final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

final imageCaptureServiceProvider = Provider<ImageCaptureService>((ref) {
  return DeviceImageCaptureService(ref.watch(imagePickerProvider));
});

final vendorLocalDataSourceProvider = Provider<VendorLocalDataSource>((ref) {
  return VendorLocalDataSourceImpl();
});

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl(ref.watch(vendorLocalDataSourceProvider));
});

final collectionLocalDataSourceProvider = Provider<CollectionLocalDataSource>((ref) {
  return CollectionLocalDataSourceImpl(ref.watch(sharedPreferencesProvider));
});

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepositoryImpl(ref.watch(collectionLocalDataSourceProvider));
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
