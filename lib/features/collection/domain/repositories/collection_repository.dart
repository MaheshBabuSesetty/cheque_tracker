import '../entities/collection_record.dart';

/// Persistence + (eventually) sync for submitted collections. Today's
/// implementation is local-only (see `CollectionLocalDataSource`); a real
/// "push to the web application tracker" step would sit behind this same
/// interface without presentation/domain code changing.
abstract class CollectionRepository {
  Future<List<CollectionRecord>> getAll();

  /// Persists [record] and returns the stored copy (e.g. with a
  /// server-assigned status, once there's a real backend).
  Future<CollectionRecord> submit(CollectionRecord record);

  Future<CollectionRecord?> getById(String id);
}
