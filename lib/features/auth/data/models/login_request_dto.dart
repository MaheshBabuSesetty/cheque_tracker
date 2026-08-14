import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request_dto.freezed.dart';
part 'login_request_dto.g.dart';

/// Request body for `POST /auth/login`. A `@freezed` value object buys
/// equality/`copyWith`/`toString` for free — handy in datasource tests that
/// assert on what was sent.
@freezed
abstract class LoginRequestDto with _$LoginRequestDto {
  const factory LoginRequestDto({
    required String agentId,
    required String password,
  }) = _LoginRequestDto;

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);
}
