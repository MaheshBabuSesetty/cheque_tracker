import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../domain/usecases/get_collection_detail.dart';
import '../../domain/usecases/get_collections.dart';
import '../../domain/usecases/get_vendors.dart';
import '../../domain/usecases/scan_cheque.dart';
import '../../domain/usecases/scan_emirates_id.dart';
import '../../domain/usecases/submit_collection.dart';
import '../../domain/usecases/sync_vendors.dart';

/// Usecase providers, each depending on the repository/service
/// abstractions from the DI composition root — never on the concrete
/// implementations directly.
final getVendorsProvider = Provider<GetVendors>((ref) {
  return GetVendors(ref.watch(vendorRepositoryProvider));
});

final syncVendorsProvider = Provider<SyncVendors>((ref) {
  return SyncVendors(ref.watch(vendorRepositoryProvider));
});

final getCollectionsProvider = Provider<GetCollections>((ref) {
  return GetCollections(ref.watch(collectionRepositoryProvider));
});

final getCollectionDetailProvider = Provider<GetCollectionDetail>((ref) {
  return GetCollectionDetail(ref.watch(collectionRepositoryProvider));
});

final submitCollectionProvider = Provider<SubmitCollection>((ref) {
  return SubmitCollection(ref.watch(collectionRepositoryProvider));
});

final scanEmiratesIdProvider = Provider<ScanEmiratesId>((ref) {
  return ScanEmiratesId(ref.watch(emiratesIdOcrServiceProvider));
});

final scanChequeProvider = Provider<ScanCheque>((ref) {
  return ScanCheque(ref.watch(chequeOcrServiceProvider));
});
