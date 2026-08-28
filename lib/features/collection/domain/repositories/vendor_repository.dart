import '../entities/vendor.dart';

/// The vendor master, synced read-only from the web application. Kept as
/// its own small interface (Interface Segregation) rather than folded into
/// [CollectionRepository] — nothing about fetching vendors overlaps with
/// submitting/listing collections.
abstract class VendorRepository {
  /// Vendors with at least one cheque on file, regardless of that cheque's
  /// status — not the full vendor master, and not only vendors with a
  /// currently-collectible cheque (`GET /vendors/available-for-collection`).
  ///
  /// Cache-first: returns whatever [syncVendors] last stored on-device if
  /// that cache is non-empty, only hitting the network when nothing has
  /// been synced yet — so the vendor picker keeps working offline between
  /// syncs. Callers that need a guaranteed-fresh list should call
  /// [syncVendors] instead.
  Future<List<Vendor>> getVendors();

  /// Always hits the network, overwrites the on-device cache with the
  /// result, and returns it — used right after login, and for a manual
  /// "refresh" action, so [getVendors] has fresh data to read from.
  Future<List<Vendor>> syncVendors();
}
