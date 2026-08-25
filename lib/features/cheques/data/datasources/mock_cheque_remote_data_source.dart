import '../../domain/entities/cheque_audit_entry.dart';
import '../models/cheque_model.dart';
import 'cheque_remote_data_source.dart';

/// Stands in for `GET /cheques` (and friends) while DEV is unreachable
/// from a device (see `AppEnvironment`'s doc comment) — wired into DI for
/// debug builds only, per `dependency_injection.dart`. Fabricates one
/// SIGNED cheque per searched vendor name, deterministically, purely so
/// the "select a cheque" step in the collect flow has something to pick
/// in mock mode; there is no real vendor/cheque linkage behind it.
class MockChequeRemoteDataSource implements ChequeRemoteDataSource {
  @override
  Future<ChequeListResponse> getCheques({
    String? search,
    String? status,
    String? paymentType,
    int? page,
    int? pageSize,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final vendorName = search?.trim();
    final items = (status == null || status == 'SIGNED') && vendorName != null && vendorName.isNotEmpty
        ? [_chequeFor(vendorName)]
        : <ChequeModel>[];
    return (items: items, totalCount: items.length, page: page ?? 1, pageSize: pageSize ?? 100);
  }

  @override
  Future<ChequeModel> getChequeById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _chequeFor('Mock vendor');
  }

  @override
  Future<List<ChequeAuditEntry>> getChequeAudit(String id) async => [
    ChequeAuditEntry(actor: 'System', action: 'Cheque signed', timestamp: DateTime.now().subtract(const Duration(days: 2))),
  ];

  ChequeModel _chequeFor(String vendorName) {
    final seed = vendorName.hashCode.abs();
    final serial = 100000 + seed % 900000;
    return ChequeModel(
      id: 'mock-chq-$seed',
      serialNumber: serial,
      vendorId: 'mock-vendor-$seed',
      supplierName: vendorName,
      chequeType: 'Non-Nego',
      paymentType: 'STND',
      bank: 'ENBD',
      chequeNumber: 'CHQ-$serial',
      chequeDate: DateTime.now().subtract(const Duration(days: 10)),
      amount: 50000 + (seed % 200000).toDouble(),
      signedBy: 'M. Al Suwaidi',
      status: 'SIGNED',
      reference: 'REF-$serial',
    );
  }
}
