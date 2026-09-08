import 'package:cheque_tracker/features/cheques/domain/entities/cheque.dart';

/// Cheque #83038 for ROSENBERG MIDDLE EAST (FZC), status PENDING.
///
/// `signedBy` combines the two signatories shown on the cheque detail
/// screen (Signed By L1 / L2), and `reference` carries the BPN Ref —
/// [Cheque] has no dedicated fields for either.
final dummyCheque = Cheque(
  id: 'dummy-cheque-83038',
  serialNumber: 7114,
  vendorId: 'dummy-vendor-rosenberg-me',
  supplierName: 'ROSENBERG MIDDLE EAST (FZC)',
  chequeType: 'Non-Nego',
  paymentType: 'STND',
  bank: 'Emirates NBD',
  chequeNumber: '83038',
  chequeDate: DateTime(2026, 9, 23),
  amount: 7651.11,
  signedBy: 'Anand Solanki / Anil Kumar Tenneti',
  status: 'PENDING',
  reference: 'BPN-104-26-07-04287',
  prepDate: DateTime(2026, 7, 27),
);
