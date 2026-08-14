import 'package:equatable/equatable.dart';

/// A vendor from the web application's vendor master, picked as step 1 of
/// a collection. Pure domain entity — no Flutter/package imports.
class Vendor extends Equatable {
  const Vendor({required this.id, required this.name, required this.code, required this.trn});

  final String id;
  final String name;

  /// Vendor master code, e.g. "VND-0114".
  final String code;

  /// UAE Tax Registration Number.
  final String trn;

  @override
  List<Object?> get props => [id, name, code, trn];
}
