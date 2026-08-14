import 'package:cheque_tracker/core/di/dependency_injection.dart';
import 'package:cheque_tracker/core/error/failures.dart';
import 'package:cheque_tracker/core/utils/result.dart';
import 'package:cheque_tracker/features/auth/domain/entities/user.dart';
import 'package:cheque_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:cheque_tracker/features/auth/presentation/providers/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late ProviderContainer container;

  const user = User(id: '1', email: 'agent.rashid@sobha.com', name: 'Rashid Kamal');

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.getCurrentUser()).thenAnswer((_) async => const ResultSuccess(null));
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  test('build() resolves to null when there is no existing session', () async {
    final result = await container.read(authProvider.future);
    expect(result, isNull);
  });

  test('login() moves through loading and lands on AsyncData with the user', () async {
    await container.read(authProvider.future);

    when(
      () => repository.login(agentId: any(named: 'agentId'), password: any(named: 'password')),
    ).thenAnswer((_) async => const ResultSuccess(user));

    final states = <AsyncValue<User?>>[];
    container.listen(authProvider, (previous, next) => states.add(next));

    await container.read(authProvider.notifier).login(agentId: 'agent.rashid', password: 'agent123');

    expect(states.any((s) => s.isLoading), isTrue);
    expect(states.last, const AsyncData<User?>(user));
  });

  test('login() surfaces the repository Failure as AsyncError', () async {
    await container.read(authProvider.future);

    when(
      () => repository.login(agentId: any(named: 'agentId'), password: any(named: 'password')),
    ).thenAnswer((_) async => const ResultError(AuthFailure()));

    await container.read(authProvider.notifier).login(agentId: 'agent.rashid', password: 'wrong');

    final state = container.read(authProvider);
    expect(state.hasError, isTrue);
    expect(state.error, isA<AuthFailure>());
  });
}
