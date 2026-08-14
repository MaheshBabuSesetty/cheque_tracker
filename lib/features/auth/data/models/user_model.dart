import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

/// Data-layer representation of [User]: same shape, plus JSON
/// (de)serialization. Nothing in `domain` or `presentation` imports this —
/// only `data/datasources` and `data/repositories` should.
@JsonSerializable()
class UserModel extends User {
  const UserModel({required super.id, required super.email, required super.name});

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}
