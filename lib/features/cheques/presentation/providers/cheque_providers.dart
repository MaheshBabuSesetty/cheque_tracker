import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/dependency_injection.dart';
import '../../../collection/domain/entities/vendor.dart';
import '../../domain/entities/cheque.dart';
import '../../domain/usecases/get_signed_cheques_for_vendor.dart';

part 'cheque_providers.g.dart';

final getSignedChequesForVendorProvider = Provider<GetSignedChequesForVendor>((ref) {
  return GetSignedChequesForVendor(ref.watch(chequeRepositoryProvider));
});

/// The SIGNED cheques available to collect for one vendor — backs the
/// "select a cheque" picker in the collect flow. Keyed by [vendor] so
/// switching vendors in the picker re-fetches automatically.
@riverpod
Future<List<Cheque>> signedChequesForVendor(Ref ref, Vendor vendor) {
  return ref.watch(getSignedChequesForVendorProvider)(vendor);
}
