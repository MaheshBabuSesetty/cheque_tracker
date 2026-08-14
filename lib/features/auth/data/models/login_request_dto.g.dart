// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    _LoginRequestDto(
      agentId: json['agentId'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(_LoginRequestDto instance) =>
    <String, dynamic>{
      'agentId': instance.agentId,
      'password': instance.password,
    };
