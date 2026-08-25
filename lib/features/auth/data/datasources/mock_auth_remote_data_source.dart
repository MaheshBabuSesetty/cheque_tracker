import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Stands in for the real backend while DEV is unreachable from a device
/// (see `AppEnvironment`'s doc comment for the Cloudflare/custom-domain
/// blocker) — wired into DI for debug builds only, per
/// `dependency_injection.dart`. Accepts exactly the demo VRM credentials
/// ([AppConstants.demoUsername] / [AppConstants.demoPassword]) and otherwise
/// fails the same way the real API would.
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthSession> login({required String username, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final matches = username.trim().toLowerCase() == AppConstants.demoUsername && password == AppConstants.demoPassword;
    if (!matches) {
      throw const AuthException('Invalid username or password.');
    }
    return _mockSession();
  }

  @override
  Future<AuthSession> refresh({required String refreshToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockSession();
  }

  @override
  Future<void> logout({required String refreshToken}) async {}

  @override
  Future<UserModel> getCurrentUser() async {
    throw const AuthException();
  }

  AuthSession _mockSession() {
    final now = DateTime.now().toUtc();
    return (
      accessToken: 'mock-access-${Random().nextInt(1 << 32)}',
      accessTokenExpiresAtUtc: now.add(const Duration(minutes: 15)),
      refreshToken: 'mock-refresh-${Random().nextInt(1 << 32)}',
      refreshTokenExpiresAtUtc: now.add(const Duration(days: 14)),
      user: const UserModel(
        id: 'agent-rashid',
        email: 'agent.rashid@sobha.com',
        name: 'Rashid Kamal',
        roles: ['VRM'],
      ),
    );
  }
}
