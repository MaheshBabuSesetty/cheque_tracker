import 'package:equatable/equatable.dart';

/// Result of scanning a captured cheque copy (step 4). Only AED and USD are
/// accepted currencies — [accepted] is false for anything else, in which
/// case [bank]/[chequeNumber]/[amount] are not populated (the agent must
/// recapture rather than record the cheque).
class ChequeScan extends Equatable {
  const ChequeScan({
    required this.detectedCurrency,
    required this.accepted,
    this.bank,
    this.confidence,
    this.chequeNumber,
    this.amount,
  });

  final String detectedCurrency;
  final bool accepted;
  final String? bank;
  final String? confidence;
  final String? chequeNumber;
  final double? amount;

  @override
  List<Object?> get props => [detectedCurrency, accepted, bank, confidence, chequeNumber, amount];
}
