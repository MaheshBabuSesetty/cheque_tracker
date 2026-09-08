import 'package:equatable/equatable.dart';

/// One row of `GET /collections` — deliberately slim (no attachment URLs,
/// no Emirates ID detail, no amount). Fetch [CollectionRecord] via
/// `GET /collections/{chequeId}` for the full detail when the user taps in.
class CollectionSummary extends Equatable {
  const CollectionSummary({
    required this.chequeId,
    required this.vendorName,
    required this.chequeNumber,
    required this.repName,
    required this.repMobile,
    required this.timestamp,
  });

  final String chequeId;
  final String vendorName;
  final String chequeNumber;
  final String repName;
  final String repMobile;
  final DateTime timestamp;

  @override
  List<Object?> get props => [chequeId, vendorName, chequeNumber, repName, repMobile, timestamp];
}
