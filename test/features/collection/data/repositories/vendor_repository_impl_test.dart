import 'package:cheque_tracker/features/collection/data/datasources/vendor_local_data_source.dart';
import 'package:cheque_tracker/features/collection/data/datasources/vendor_remote_data_source.dart';
import 'package:cheque_tracker/features/collection/data/models/vendor_model.dart';
import 'package:cheque_tracker/features/collection/data/repositories/vendor_repository_impl.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockVendorRemoteDataSource extends Mock implements VendorRemoteDataSource {}

class MockVendorLocalDataSource extends Mock implements VendorLocalDataSource {}

void main() {
  late MockVendorRemoteDataSource remote;
  late MockVendorLocalDataSource local;
  late VendorRepositoryImpl repository;

  const cachedVendor = VendorModel(id: 'v1', name: 'Cached Vendor', code: null, trn: null);
  const freshVendor = VendorModel(id: 'v2', name: 'Fresh Vendor', code: null, trn: null);

  setUpAll(() {
    registerFallbackValue(<Vendor>[]);
  });

  setUp(() {
    remote = MockVendorRemoteDataSource();
    local = MockVendorLocalDataSource();
    repository = VendorRepositoryImpl(remote, local);
  });

  test('getVendors returns the cache without touching the network when the cache is non-empty', () async {
    when(() => local.getCachedVendors()).thenAnswer((_) async => [cachedVendor]);

    final result = await repository.getVendors();

    expect(result, [cachedVendor]);
    verifyNever(() => remote.getAvailableForCollection());
  });

  test('getVendors falls back to a network sync when the cache is empty', () async {
    when(() => local.getCachedVendors()).thenAnswer((_) async => []);
    when(() => remote.getAvailableForCollection()).thenAnswer((_) async => [freshVendor]);
    when(() => local.cacheVendors(any())).thenAnswer((_) async {});

    final result = await repository.getVendors();

    expect(result, [freshVendor]);
    verify(() => local.cacheVendors([freshVendor])).called(1);
  });

  test('syncVendors always hits the network and overwrites the cache, even if one already exists', () async {
    when(() => remote.getAvailableForCollection()).thenAnswer((_) async => [freshVendor]);
    when(() => local.cacheVendors(any())).thenAnswer((_) async {});

    final result = await repository.syncVendors();

    expect(result, [freshVendor]);
    verifyNever(() => local.getCachedVendors());
    verify(() => local.cacheVendors([freshVendor])).called(1);
  });
}
