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

  // App
  static const String appVersion = '/app/version';
}
