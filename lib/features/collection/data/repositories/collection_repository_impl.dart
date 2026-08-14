import '../../domain/entities/collection_record.dart';
import '../../domain/repositories/collection_repository.dart';
import '../datasources/collection_local_data_source.dart';

class CollectionRepositoryImpl implements CollectionRepository {
  const CollectionRepositoryImpl(this._localDataSource);

  final CollectionLocalDataSource _localDataSource;

  @override
  Future<List<CollectionRecord>> getAll() => _localDataSource.getAll();

  @override
  Future<CollectionRecord> submit(CollectionRecord record) async {
    await _localDataSource.add(record);
    return record;
  }

  @override
  Future<CollectionRecord?> getById(String id) => _localDataSource.getById(id);
}
