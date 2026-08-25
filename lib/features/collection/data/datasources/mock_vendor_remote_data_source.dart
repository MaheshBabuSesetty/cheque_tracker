import '../../domain/entities/vendor.dart';
import 'vendor_remote_data_source.dart';

/// Stands in for `GET /vendors/available-for-collection` while DEV is
/// unreachable from a device (see `AppEnvironment`'s doc comment) — wired
/// into DI for debug builds only, per `dependency_injection.dart`. A real
/// vendor sync would populate `code`/`trn`; both stay non-null here purely
/// so the picker sheet has something to show under each name in mock mode.
class MockVendorRemoteDataSource implements VendorRemoteDataSource {
  static final _vendors = [
    const Vendor(id: 'v1', name: 'Al Falah Building Materials LLC', code: 'VND-0114', trn: '100234567800003'),
    const Vendor(id: 'v2', name: 'Gulf Steel Trading Co.', code: 'VND-0127', trn: '100298871200003'),
    const Vendor(id: 'v3', name: 'Continental MEP Contracting', code: 'VND-0141', trn: '100377419900003'),
    const Vendor(id: 'v4', name: 'Al Reem Facilities Services', code: 'VND-0158', trn: '100411203400003'),
    const Vendor(id: 'v5', name: 'Skyline Aluminium & Glass', code: 'VND-0163', trn: '100455620100003'),
    const Vendor(id: 'v6', name: 'Desert Rose Interiors', code: 'VND-0172', trn: '100488102900003'),
    const Vendor(id: 'v7', name: 'Falcon Pumps & Valves', code: 'VND-0189', trn: '100512338700003'),
    const Vendor(id: 'v8', name: 'Emirates Scaffolding LLC', code: 'VND-0194', trn: '100566419200003'),
    const Vendor(id: 'v9', name: 'Precision Formwork Systems', code: 'VND-0208', trn: '100601277300003'),
    const Vendor(id: 'v10', name: 'Bin Yousef Trading', code: 'VND-0219', trn: '100644901500003'),
    const Vendor(id: 'v11', name: 'Al Ameen Concrete Products', code: 'VND-0226', trn: '100678224400003'),
    const Vendor(id: 'v12', name: 'Meydan Landscaping LLC', code: 'VND-0233', trn: '100712889000003'),
  ];

  @override
  Future<List<Vendor>> getAvailableForCollection() async => _vendors;
}
