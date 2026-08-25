import 'package:equatable/equatable.dart';

/// Pure domain entity — no Flutter, no `json_annotation`, no `dio`. The
/// `data` layer's `UserModel` extends this and adds serialization.
class User extends Equatable {
  const User({required this.id, required this.email, required this.name, this.roles = const []});

  final String id;
  final String email;
  final String name;

  /// Server-assigned role names, e.g. `['VRM']`. The collection flow
  /// (vendor list + submit collection) is gated on [isVrm] — those two
  /// endpoints are VRM-only server-side too, so this is a UX nicety, not
  /// the real enforcement boundary.
  final List<String> roles;

  bool get isVrm => roles.contains('VRM');

  @override
  List<Object?> get props => [id, email, name, roles];
}
