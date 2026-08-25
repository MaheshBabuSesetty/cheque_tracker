import '../entities/vendor.dart';

/// The vendor master, synced read-only from the web application. Kept as
/// its own small interface (Interface Segregation) rather than folded into
/// [CollectionRepository] — nothing about fetching vendors overlaps with
/// submitting/listing collections.
abstract class VendorRepository {
  /// Vendors with at least one cheque on file, regardless of that cheque's
  /// status — not the full vendor master, and not only vendors with a
  /// currently-collectible cheque (`GET /vendors/available-for-collection`).
  Future<List<Vendor>> getVendors();
}
