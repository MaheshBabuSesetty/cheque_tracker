import 'package:cheque_tracker/core/error/failures.dart';
import 'package:cheque_tracker/core/utils/result.dart';
import 'package:cheque_tracker/features/auth/domain/entities/user.dart';
import 'package:cheque_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:cheque_tracker/features/auth/domain/usecases/login_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late LoginUser usecase;

  const user = User(id: '1', email: 'agent.rashid@sobha.com', name: 'Rashid Kamal');

  setUp(() {
    repository = MockAuthRepository();
    usecase = LoginUser(repository);
  });

  test('delegates to the repository and returns its ResultSuccess', () async {
    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        rememberDevice: any(named: 'rememberDevice'),
      ),
    ).thenAnswer((_) async => const ResultSuccess(user));

    final result = await usecase(username: 'agent.rashid', password: 'agent123', rememberDevice: true);

    expect(result, isA<ResultSuccess<User>>());
    expect((result as ResultSuccess<User>).data, user);
    verify(
      () => repository.login(username: 'agent.rashid', password: 'agent123', rememberDevice: true),
    ).called(1);
  });

  test('propagates a ResultError when the repository rejects the credentials', () async {
    when(
      () => repository.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
        rememberDevice: any(named: 'rememberDevice'),
      ),
    ).thenAnswer((_) async => const ResultError(AuthFailure()));

    final result = await usecase(username: 'agent.rashid', password: 'wrong', rememberDevice: true);

    expect(result, isA<ResultError<User>>());
    expect((result as ResultError<User>).failure, isA<AuthFailure>());
  });
}
