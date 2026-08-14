import '../entities/vendor.dart';
import '../repositories/vendor_repository.dart';

class GetVendors {
  const GetVendors(this._repository);

  final VendorRepository _repository;

  Future<List<Vendor>> call() => _repository.getVendors();
}
