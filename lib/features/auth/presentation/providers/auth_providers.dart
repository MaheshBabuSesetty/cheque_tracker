import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';

/// Usecase providers. Each depends on the [AuthRepository] abstraction from
/// the DI composition root, never on `AuthRepositoryImpl`.
final loginUserProvider = Provider<LoginUser>((ref) {
  return LoginUser(ref.watch(authRepositoryProvider));
});

final logoutUserProvider = Provider<LogoutUser>((ref) {
  return LogoutUser(ref.watch(authRepositoryProvider));
});

final getCurrentUserProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});
