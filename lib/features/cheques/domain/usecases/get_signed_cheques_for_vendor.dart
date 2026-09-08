import '../../../collection/domain/entities/vendor.dart';
import '../entities/cheque.dart';
import '../repositories/cheque_repository.dart';

/// The SIGNED cheques available to collect for one vendor.
///
/// There is no `vendorId` filter on `GET /cheques` today, so this uses the
/// contract's documented workaround: filter by `status=SIGNED` and
/// `search=<vendor name>` (a free-text match over supplier/cheque no./PO/
/// signed-by/bank). If the backend ever adds an exact `vendorId` filter,
/// swap it in here — nothing above this usecase needs to change.
class GetSignedChequesForVendor {
  const GetSignedChequesForVendor(this._repository);

  final ChequeRepository _repository;

  Future<List<Cheque>> call(Vendor vendor) async {
    final page = await _repository.getCheques(status: 'SIGNED', search: vendor.name);
    return page.items;
  }
}
