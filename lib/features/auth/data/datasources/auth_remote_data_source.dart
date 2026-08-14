import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../models/login_request_dto.dart';
import '../models/user_model.dart';

typedef AuthSession = ({String token, UserModel user});

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String agentId, required String password});
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

/// Real backend-backed implementation. Not currently wired into DI — there
/// is no live auth API yet, so [MockAuthRemoteDataSource] stands in for it.
/// Swapping back is a one-line change in `dependency_injection.dart` once a
/// backend exists; nothing above `data/` needs to know.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> login({required String agentId, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: LoginRequestDto(agentId: agentId, password: password).toJson(),
      );
      final data = response.data!;
      return (
        token: data['token'] as String,
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const AuthException();
      throw const ServerException();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiEndpoints.logout);
    } on DioException {
      throw const ServerException();
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.currentUser);
      return UserModel.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) throw const AuthException();
      throw const ServerException();
    }
  }
}
