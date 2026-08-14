import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../datasources/vendor_local_data_source.dart';

class VendorRepositoryImpl implements VendorRepository {
  const VendorRepositoryImpl(this._localDataSource);

  final VendorLocalDataSource _localDataSource;

  @override
  Future<List<Vendor>> getVendors() => _localDataSource.getVendors();
}
