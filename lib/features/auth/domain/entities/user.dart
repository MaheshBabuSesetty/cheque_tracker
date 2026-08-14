import 'package:equatable/equatable.dart';

/// Pure domain entity — no Flutter, no `json_annotation`, no `dio`. The
/// `data` layer's `UserModel` extends this and adds serialization.
class User extends Equatable {
  const User({required this.id, required this.email, required this.name});

  final String id;
  final String email;
  final String name;

  @override
  List<Object?> get props => [id, email, name];
}
