import 'package:cheque_tracker/features/collection/data/datasources/vendor_local_data_source.dart';
import 'package:cheque_tracker/features/collection/domain/entities/vendor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late VendorLocalDataSourceImpl dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dataSource = VendorLocalDataSourceImpl(await SharedPreferences.getInstance());
  });

  test('getCachedVendors is empty before anything has been cached', () async {
    expect(await dataSource.getCachedVendors(), isEmpty);
  });

  test('cacheVendors then getCachedVendors round-trips every field', () async {
    const vendors = [
      Vendor(id: 'v1', name: 'Al Falah Building Materials LLC', code: 'VND-0114', trn: '100234567800003'),
      Vendor(id: 'v2', name: 'Vendor With No Code Or TRN', code: null, trn: null),
    ];

    await dataSource.cacheVendors(vendors);
    final cached = await dataSource.getCachedVendors();

    expect(cached.length, 2);
    expect(cached[0].id, 'v1');
    expect(cached[0].name, 'Al Falah Building Materials LLC');
    expect(cached[0].code, 'VND-0114');
    expect(cached[0].trn, '100234567800003');
    expect(cached[1].code, isNull);
    expect(cached[1].trn, isNull);
  });

  test('a later cacheVendors call overwrites the previous cache rather than appending', () async {
    await dataSource.cacheVendors(const [Vendor(id: 'v1', name: 'First', code: null, trn: null)]);
    await dataSource.cacheVendors(const [Vendor(id: 'v2', name: 'Second', code: null, trn: null)]);

    final cached = await dataSource.getCachedVendors();
    expect(cached.length, 1);
    expect(cached.single.id, 'v2');
  });
}
