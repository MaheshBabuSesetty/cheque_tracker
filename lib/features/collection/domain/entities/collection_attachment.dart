import 'package:equatable/equatable.dart';

/// One entry in a [CollectionRecord]'s `supportingDocuments` — fetched via
/// `GET /cheques/{chequeId}/collection/supporting-documents/{id}` using
/// [id], scoped to the cheque it belongs to.
class CollectionAttachment extends Equatable {
  const CollectionAttachment({required this.id, required this.fileName, required this.url});

  final String id;
  final String fileName;

  /// Relative API path — resolve against the configured base URL and fetch
  /// with the current bearer token (see `AuthenticatedNetworkImage`).
  final String url;

  @override
  List<Object?> get props => [id, fileName, url];
}
