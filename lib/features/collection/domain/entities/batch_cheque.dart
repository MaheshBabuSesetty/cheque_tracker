import 'package:equatable/equatable.dart';

/// One of the *other* cheques collected in the same visit as a
/// [CollectionRecord] — an entry of the detail response's `batchCheques`.
class BatchCheque extends Equatable {
  const BatchCheque({
    required this.chequeId,
    required this.chequeNumber,
    required this.amount,
    this.currency = 'AED',
  });

  final String chequeId;
  final String chequeNumber;
  final double amount;
  final String currency;

  @override
  List<Object?> get props => [chequeId, chequeNumber, amount, currency];
}
