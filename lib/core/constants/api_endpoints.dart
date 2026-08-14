/// Centralized API route fragments, joined onto [ApiEndpoints.baseUrl] by the
/// network layer. Kept separate from [AppConstants] so swapping backends
/// only touches this file.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = 'https://api.chequetracker.example.com';

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String currentUser = '/auth/me';
}
