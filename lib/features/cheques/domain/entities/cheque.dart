import 'package:equatable/equatable.dart';

/// A cheque from the shared web/mobile cheque tracker. A cheque becomes
/// collectible once its [status] is `'SIGNED'` — `ISSUED` is the *result*
/// of a successful collection submission, not a precondition for one.
///
/// List (`GET /cheques`) and detail (`GET /cheques/{id}`) share this one
/// entity: the list-shape fields below are always present; everything after
/// them is detail-only (or Data-Lake-sourced, currently always `null`) and
/// stays `null` on a cheque built from a list response.
class Cheque extends Equatable {
  const Cheque({
    required this.id,
    required this.serialNumber,
    required this.vendorId,
    required this.supplierName,
    required this.chequeType,
    required this.paymentType,
    required this.bank,
    required this.chequeNumber,
    required this.chequeDate,
    required this.amount,
    required this.signedBy,
    required this.status,
    this.reference,
    this.poNumber,
    this.issuedDate,
    this.prepDate,
    this.receivedDate,
    this.siteTeamApprovalReceived,
    this.accountsTeamApprovalReceived,
    this.collectedBy,
    this.collectorMobile,
    this.canMarkSigned = false,
    this.canMarkIssued = false,
    this.canCancel = false,
    this.createdAt,
    this.createdByName,
    this.updatedAt,
    this.updatedByName,
  });

  final String id;
  final int serialNumber;
  final String vendorId;
  final String supplierName;
  final String chequeType;
  final String paymentType;
  final String bank;
  final String chequeNumber;
  final DateTime chequeDate;
  final double amount;
  final String signedBy;

  /// `'SIGNED'` | `'PENDING'` | `'ISSUED'` | `'CANCELLED'` — kept as the
  /// raw wire value rather than an enum since it's mostly pass-through
  /// display/query-filter text, not branched on beyond "is this SIGNED".
  final String status;

  /// Use this for any "ref" display — detail-only.
  final String? reference;
  final String? poNumber;
  final DateTime? issuedDate;

  /// Data-Lake-sourced, currently always `null` (reserved for a future
  /// sync) — not an error state.
  final DateTime? prepDate;
  final DateTime? receivedDate;

  final bool? siteTeamApprovalReceived;
  final bool? accountsTeamApprovalReceived;

  /// Populated once collected.
  final String? collectedBy;
  final String? collectorMobile;

  /// Server-computed — trust these over re-deriving from [status].
  final bool canMarkSigned;
  final bool canMarkIssued;
  final bool canCancel;

  final DateTime? createdAt;
  final String? createdByName;
  final DateTime? updatedAt;
  final String? updatedByName;

  bool get isSigned => status == 'SIGNED';

  @override
  List<Object?> get props => [
        id,
        serialNumber,
        vendorId,
        supplierName,
        chequeType,
        paymentType,
        bank,
        chequeNumber,
        chequeDate,
        amount,
        signedBy,
        status,
        reference,
        poNumber,
        issuedDate,
        prepDate,
        receivedDate,
        siteTeamApprovalReceived,
        accountsTeamApprovalReceived,
        collectedBy,
        collectorMobile,
        canMarkSigned,
        canMarkIssued,
        canCancel,
        createdAt,
        createdByName,
        updatedAt,
        updatedByName,
      ];
}
