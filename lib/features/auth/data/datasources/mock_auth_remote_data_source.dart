import 'dart:math';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// Stands in for a real backend until one exists. Accepts exactly the demo
/// field-agent credentials from the approved design
/// ([AppConstants.demoAgentId] / [AppConstants.demoAgentPassword]) and
/// otherwise fails the same way a real API would (`AuthException`).
///
/// This is the concrete [AuthRemoteDataSource] wired into DI today; see
/// `dependency_injection.dart`. Swapping to [AuthRemoteDataSourceImpl] once
/// a backend is live is a one-line change there — nothing above `data/`
/// needs to know which one is active (Open/Closed, Liskov Substitution).
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  @override
  Future<AuthSession> login({required String agentId, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final matches = agentId.trim().toLowerCase() == AppConstants.demoAgentId &&
        password == AppConstants.demoAgentPassword;
    if (!matches) {
      throw const AuthException('That agent ID or password is not recognised.');
    }
    return (
      token: 'mock-token-${Random().nextInt(1 << 32)}',
      user: const UserModel(id: 'agent-rashid', email: 'agent.rashid@sobha.com', name: 'Rashid Kamal'),
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<UserModel> getCurrentUser() async {
    throw const AuthException();
  }
}
