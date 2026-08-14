// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session state for the whole app: `null` data means signed out, an error
/// means the last action (login) failed. Modeled with [AsyncValue] instead
/// of a manual `isLoading`/`error` pair of fields.

@ProviderFor(AuthNotifier)
final authProvider = AuthNotifierProvider._();

/// Session state for the whole app: `null` data means signed out, an error
/// means the last action (login) failed. Modeled with [AsyncValue] instead
/// of a manual `isLoading`/`error` pair of fields.
final class AuthNotifierProvider
    extends $AsyncNotifierProvider<AuthNotifier, User?> {
  /// Session state for the whole app: `null` data means signed out, an error
  /// means the last action (login) failed. Modeled with [AsyncValue] instead
  /// of a manual `isLoading`/`error` pair of fields.
  AuthNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authNotifierHash();

  @$internal
  @override
  AuthNotifier create() => AuthNotifier();
}

String _$authNotifierHash() => r'a16f5c4eac204f27dbb9c786a1df9cde6c73e17e';

/// Session state for the whole app: `null` data means signed out, an error
/// means the last action (login) failed. Modeled with [AsyncValue] instead
/// of a manual `isLoading`/`error` pair of fields.

abstract class _$AuthNotifier extends $AsyncNotifier<User?> {
  FutureOr<User?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<User?>, User?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<User?>, User?>,
              AsyncValue<User?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
