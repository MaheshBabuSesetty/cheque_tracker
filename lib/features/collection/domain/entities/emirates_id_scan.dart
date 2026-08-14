import 'package:equatable/equatable.dart';

/// Result of scanning the front of an Emirates ID (step 3 of a collection).
/// Produced by `EmiratesIdOcrService` — see that interface for why this is
/// modeled as its own value rather than fields bolted onto the draft.
class EmiratesIdScan extends Equatable {
  const EmiratesIdScan({
    required this.idNumber,
    required this.name,
    required this.nationality,
    required this.expiry,
    required this.confidence,
  });

  final String idNumber;
  final String name;
  final String nationality;
  final String expiry;

  /// e.g. "97%" — surfaced to the agent, not used for any logic.
  final String confidence;

  @override
  List<Object?> get props => [idNumber, name, nationality, expiry, confidence];
}
