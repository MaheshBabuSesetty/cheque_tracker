import '../entities/vendor.dart';

/// The vendor master, synced read-only from the web application. Kept as
/// its own small interface (Interface Segregation) rather than folded into
/// [CollectionRepository] — nothing about fetching vendors overlaps with
/// submitting/listing collections.
abstract class VendorRepository {
  Future<List<Vendor>> getVendors();
}
