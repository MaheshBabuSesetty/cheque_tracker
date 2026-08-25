import '../../domain/entities/collection_draft.dart';
import '../../domain/entities/collection_record.dart';
import '../../domain/entities/collection_summary.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_remote_data_source.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  const CollectionRepositoryImpl(this._remoteDataSource);

  final CollectionRemoteDataSource _remoteDataSource;

  @override
  Future<CollectionRecord> submit(CollectionDraft draft) => _remoteDataSource.submit(draft);

  @override
  Future<List<CollectionSummary>> getAll() => _remoteDataSource.getAll();

  @override
  Future<CollectionRecord> getByChequeId(String chequeId) => _remoteDataSource.getByChequeId(chequeId);
}
