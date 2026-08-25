import '../entities/cheque.dart';
import '../entities/cheque_audit_entry.dart';
import '../entities/cheque_page.dart';

abstract class ChequeRepository {
  /// `GET /cheques`. All filters optional; `page`/`pageSize` default to the
  /// server's own defaults (1 / 100) when omitted.
  Future<ChequePage> getCheques({String? search, String? status, String? paymentType, int? page, int? pageSize});

  Future<Cheque> getChequeById(String id);

  /// Newest first.
  Future<List<ChequeAuditEntry>> getChequeAudit(String id);
}
