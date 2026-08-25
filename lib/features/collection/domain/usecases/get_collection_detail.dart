import '../entities/collection_record.dart';
import '../repositories/collection_repository.dart';

class GetCollectionDetail {
  const GetCollectionDetail(this._repository);

  final CollectionRepository _repository;

  Future<CollectionRecord> call(String chequeId) => _repository.getByChequeId(chequeId);
}
