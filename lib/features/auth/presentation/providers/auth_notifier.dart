import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../collection/presentation/providers/collection_providers.dart';
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
    final user = switch (result) {
      ResultSuccess(:final data) => data,
      ResultError() => null,
    };
    unawaited(_syncVendorsIfVrm(user));
    return user;
  }

  Future<void> login({required String username, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(loginUserProvider)(username: username, password: password);
    state = switch (result) {
      ResultSuccess(:final data) => AsyncData(data),
      ResultError(:final failure) => AsyncError(failure, StackTrace.current),
    };
    if (result is ResultSuccess<User>) unawaited(_syncVendorsIfVrm(result.data));
  }

  /// Refreshes the on-device vendor-master cache right after a fresh login
  /// and on every session resume (cold start with an existing session) —
  /// VRM-only server-side, so non-VRM accounts skip it entirely rather than
  /// hitting a guaranteed 403. Never awaited by callers and never rethrows:
  /// a sync failure here must not block sign-in or app startup — the
  /// vendor picker still works via `GetVendors`'s cache-or-fetch fallback.
  Future<void> _syncVendorsIfVrm(User? user) async {
    if (user == null || !user.isVrm) return;
    try {
      await ref.read(syncVendorsProvider)();
    } catch (_) {
      // Swallowed intentionally — see doc comment above.
    }
  }

  Future<void> logout() async {
    await ref.read(logoutUserProvider)();
    state = const AsyncData(null);
  }
}
