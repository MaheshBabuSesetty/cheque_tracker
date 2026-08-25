import 'package:equatable/equatable.dart';

/// One entry in a cheque's audit trail (`GET /cheques/{id}/audit`),
/// newest first.
class ChequeAuditEntry extends Equatable {
  const ChequeAuditEntry({required this.actor, required this.action, required this.timestamp});

  final String actor;
  final String action;
  final DateTime timestamp;

  @override
  List<Object?> get props => [actor, action, timestamp];
}
