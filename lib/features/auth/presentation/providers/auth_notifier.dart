import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';

part 'auth_notifier.g.dart';

/// Session state for the whole app: `null` data means signed out, an error
/// means the last action (login) failed. Modeled with [AsyncValue] instead
/// of a manual `isLoading`/`error` pair of fields.
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<User?> build() async {
    final result = await ref.read(getCurrentUserProvider)();
    return switch (result) {
      ResultSuccess(:final data) => data,
      ResultError() => null,
    };
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(loginUserProvider)(username: username, password: password);
    state = switch (result) {
      ResultSuccess(:final data) => AsyncData(data),
      ResultError(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }

  Future<void> logout() async {
    await ref.read(logoutUserProvider)();
    state = const AsyncData(null);
  }
}
