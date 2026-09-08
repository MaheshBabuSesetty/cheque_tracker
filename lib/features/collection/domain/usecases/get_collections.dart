import '../entities/collection_summary.dart';
import '../repositories/collection_repository.dart';

class GetCollections {
  const GetCollections(this._repository);

  final CollectionRepository _repository;

  Future<List<CollectionSummary>> call() => _repository.getAll();
}
