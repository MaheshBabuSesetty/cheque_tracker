import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_error_parser.dart';
import '../models/login_request_dto.dart';
import '../models/user_model.dart';

typedef AuthSession = ({
  String accessToken,
  DateTime accessTokenExpiresAtUtc,
  String refreshToken,
  DateTime refreshTokenExpiresAtUtc,
  UserModel user,
});

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String username, required String password});

  /// Exchanges an already-verified SSO identity token (see
  /// `SsoAuthService.signIn`) for this app's own session — mirrors [login]
  /// in every way except the credential: the backend validates [idToken]
  /// against the [provider]'s public keys/issuer rather than a password,
  /// then looks up/provisions the matching [AuthSession.user] the same way.
  Future<AuthSession> loginWithSso({required String idToken, required String provider});
  Future<AuthSession> refresh({required String refreshToken});
  Future<void> logout({required String refreshToken});
  Future<UserModel> getCurrentUser();
}

/// Real backend-backed implementation, wired into DI unconditionally (see
/// `dependency_injection.dart`'s `authRemoteDataSourceProvider`) — every
/// build talks to the live DEV API.
///
/// Deliberately split across two [Dio] instances: [unauthenticatedDio]
/// carries no [AuthInterceptor] and is used for login/refresh/logout, which
/// never need a bearer token and must never trigger the refresh-on-401
/// logic; [dio] is the normal authenticated client, used only for
/// `getCurrentUser` (`GET /auth/me`), which does need the bearer token the
/// interceptor already attaches from storage.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl({required this.unauthenticatedDio, required this.dio});

  final Dio unauthenticatedDio;
  final Dio dio;

  @override
  Future<AuthSession> login({required String username, required String password}) async {
    try {
      final response = await unauthenticatedDio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: LoginRequestDto(username: username, password: password).toJson(),
      );
      return _sessionFromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<AuthSession> loginWithSso({required String idToken, required String provider}) async {
    try {
      final response = await unauthenticatedDio.post<Map<String, dynamic>>(
        ApiEndpoints.ssoLogin,
        data: {'idToken': idToken, 'provider': provider},
      );
      return _sessionFromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    try {
      final response = await unauthenticatedDio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );
      return _sessionFromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    try {
      await unauthenticatedDio.post<void>(ApiEndpoints.logout, data: {'refreshToken': refreshToken});
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(ApiEndpoints.currentUser);
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  AuthSession _sessionFromJson(Map<String, dynamic> json) => (
    accessToken: json['accessToken'] as String,
    accessTokenExpiresAtUtc: DateTime.parse(json['accessTokenExpiresAtUtc'] as String),
    refreshToken: json['refreshToken'] as String,
    refreshTokenExpiresAtUtc: DateTime.parse(json['refreshTokenExpiresAtUtc'] as String),
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}
