import '../../domain/entities/vendor.dart';
import '../../domain/repositories/vendor_repository.dart';
import '../datasources/vendor_local_data_source.dart';
import '../datasources/vendor_remote_data_source.dart';

class VendorRepositoryImpl implements VendorRepository {
  const VendorRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final VendorRemoteDataSource _remoteDataSource;
  final VendorLocalDataSource _localDataSource;

  @override
  Future<List<Vendor>> getVendors() async {
    final cached = await _localDataSource.getCachedVendors();
    if (cached.isNotEmpty) return cached;
    return syncVendors();
  }

  @override
  Future<List<Vendor>> syncVendors() async {
    final fresh = await _remoteDataSource.getAvailableForCollection();
    await _localDataSource.cacheVendors(fresh);
    return fresh;
  }
}
