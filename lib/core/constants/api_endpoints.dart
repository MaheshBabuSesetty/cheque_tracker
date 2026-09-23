import '../config/app_environment.dart';

/// Centralized API route fragments, joined onto [ApiEndpoints.baseUrl] by the
/// network layer. Kept separate from [AppConstants] so swapping backends
/// only touches this file. There is one shared REST API for web + mobile —
/// no `/api/mobile/*` surface, no mobile-specific shapes.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = AppEnvironment.apiBaseUrl;

  // Auth — none of these carry/need the bearer-attach-and-refresh interceptor.
  static const String login = '/auth/login';

  /// Confirmed live backend-side on UAT only (returns 401 on an invalid
  /// token rather than 404) as of 2026-09-22 — dev/prod hosts don't
  /// currently resolve at all, see [AppEnvironment]'s doc comment. See
  /// `AuthRemoteDataSource.loginWithSso`'s doc comment for the expected
  /// request/response contract (identical [AuthSession] shape to [login]).
  static const String ssoLogin = '/auth/sso';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';

  // Vendors
  static const String vendorsAvailableForCollection = '/vendors/available-for-collection';
  static String vendorDetail(String id) => '/vendors/$id';

  // Cheques
  static const String cheques = '/cheques';
  static String chequeDetail(String id) => '/cheques/$id';
  static String chequeAudit(String id) => '/cheques/$id/audit';
  static String chequeCollection(String chequeId) => '/cheques/$chequeId/collection';
  static String chequeCollectionFile(String chequeId, String field) =>
      '/cheques/$chequeId/collection/files/$field';
  static String chequeCollectionSupportingDocument(String chequeId, String attachmentId) =>
      '/cheques/$chequeId/collection/supporting-documents/$attachmentId';

  // Collections
  static const String collections = '/collections';
  static String collectionByChequeId(String chequeId) => '/collections/$chequeId';
}
