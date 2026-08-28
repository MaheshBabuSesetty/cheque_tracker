import '../entities/vendor.dart';
import '../repositories/vendor_repository.dart';

/// Refreshes the on-device vendor-master cache from the network — called
/// once after login (see `AuthNotifier`) and available as a manual
/// "refresh" action in the vendor picker, unlike [GetVendors] which may
/// serve a cached list without hitting the network at all.
class SyncVendors {
  const SyncVendors(this._repository);

  final VendorRepository _repository;

  Future<List<Vendor>> call() => _repository.syncVendors();
}
