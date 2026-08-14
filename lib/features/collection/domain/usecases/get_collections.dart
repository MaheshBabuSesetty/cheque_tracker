import '../entities/collection_record.dart';
import '../repositories/collection_repository.dart';

class GetCollections {
  const GetCollections(this._repository);

  final CollectionRepository _repository;

  Future<List<CollectionRecord>> call() => _repository.getAll();
}
