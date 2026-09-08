import 'package:cheque_tracker/core/error/failures.dart';
import 'package:cheque_tracker/core/utils/result.dart';
import 'package:cheque_tracker/features/auth/domain/entities/user.dart';
import 'package:cheque_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:cheque_tracker/features/auth/domain/usecases/login_with_sso.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginWithSso usecase;

  const user = User(id: '1', email: 'agent.rashid@sobha.com', name: 'Rashid Kamal');

  setUp(() {
    repository = MockAuthRepository();
    usecase = LoginWithSso(repository);
  });

  test('delegates to the repository and returns its ResultSuccess', () async {
    when(
      () => repository.loginWithSso(rememberDevice: any(named: 'rememberDevice')),
    ).thenAnswer((_) async => const ResultSuccess(user));

    final result = await usecase(rememberDevice: true);

    expect(result, isA<ResultSuccess<User?>>());
    expect((result as ResultSuccess<User?>).data, user);
    verify(() => repository.loginWithSso(rememberDevice: true)).called(1);
  });

  test('a null-data success (agent cancelled the SSO UI) passes through unchanged', () async {
    when(
      () => repository.loginWithSso(rememberDevice: any(named: 'rememberDevice')),
    ).thenAnswer((_) async => const ResultSuccess(null));

    final result = await usecase(rememberDevice: true);

    expect(result, isA<ResultSuccess<User?>>());
    expect((result as ResultSuccess<User?>).data, isNull);
  });

  test('propagates a ResultError when the token exchange fails', () async {
    when(
      () => repository.loginWithSso(rememberDevice: any(named: 'rememberDevice')),
    ).thenAnswer((_) async => const ResultError(AuthFailure()));

    final result = await usecase(rememberDevice: true);

    expect(result, isA<ResultError<User?>>());
    expect((result as ResultError<User?>).failure, isA<AuthFailure>());
  });
}
