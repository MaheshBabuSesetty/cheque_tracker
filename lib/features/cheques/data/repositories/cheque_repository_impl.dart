import '../../domain/entities/cheque.dart';
import '../../domain/entities/cheque_audit_entry.dart';
import '../../domain/entities/cheque_page.dart';
import '../../domain/repositories/cheque_repository.dart';
import '../datasources/cheque_remote_data_source.dart';

class ChequeRepositoryImpl implements ChequeRepository {
  const ChequeRepositoryImpl(this._remoteDataSource);

  final ChequeRemoteDataSource _remoteDataSource;

  @override
  Future<ChequePage> getCheques({String? search, String? status, String? paymentType, int? page, int? pageSize}) async {
    final response = await _remoteDataSource.getCheques(
      search: search,
      status: status,
      paymentType: paymentType,
      page: page,
      pageSize: pageSize,
    );
    return ChequePage(
      items: response.items,
      totalCount: response.totalCount,
      page: response.page,
      pageSize: response.pageSize,
    );
  }

  @override
  Future<Cheque> getChequeById(String id) => _remoteDataSource.getChequeById(id);

  @override
  Future<List<ChequeAuditEntry>> getChequeAudit(String id) => _remoteDataSource.getChequeAudit(id);
}
