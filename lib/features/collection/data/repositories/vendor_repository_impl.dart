import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../datasources/vendor_remote_data_source.dart';

class VendorRepositoryImpl implements VendorRepository {
  const VendorRepositoryImpl(this._remoteDataSource);

  final VendorRemoteDataSource _remoteDataSource;

  @override
  Future<List<Vendor>> getVendors() => _remoteDataSource.getAvailableForCollection();
}
