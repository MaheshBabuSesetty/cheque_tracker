import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../domain/entities/collection_draft.dart';
import '../models/collection_record_model.dart';
import '../models/collection_summary_model.dart';

abstract class CollectionRemoteDataSource {
  Future<CollectionRecordModel> submit(CollectionDraft draft);
  Future<List<CollectionSummaryModel>> getAll();
  Future<CollectionRecordModel> getByChequeId(String chequeId);
}

/// `POST /cheques/{chequeId}/collection` is one atomic multipart
/// submission — collector details, every file, and the server-side
/// SIGNED → ISSUED transition all happen in the same call. There is no
/// separate start/upload/confirm sequence.
class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  const CollectionRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<CollectionRecordModel> submit(CollectionDraft draft) async {
    final cheque = draft.cheque!;
    final idScan = draft.idScan;

    // Nationality/expiry are no longer read from OCR, but the API still
    // expects both field keys on every submission — sent empty rather than
    // omitted so a required-field validation on the server side doesn't
    // reject the request.
    final fields = <MapEntry<String, String>>[
      MapEntry('CollectorName', draft.repName.trim()),
      const MapEntry('CollectorNationality', ''),
      const MapEntry('CollectorEidExpiryDate', ''),
    ];

    final mobileDigits = draft.repMobile.replaceAll(RegExp(r'\D'), '');
    if (mobileDigits.isNotEmpty) fields.add(MapEntry('CollectorMobile', '+971 $mobileDigits'));
    if (idScan != null && idScan.idNumber.isNotEmpty) fields.add(MapEntry('CollectorEmiratesId', idScan.idNumber));

    // `SupportingDocuments` must be repeated under the identical field name
    // for each file, not `SupportingDocuments[0]`/`[1]` — `FormData.files`
    // (a list of entries) supports that natively.
    final files = <MapEntry<String, MultipartFile>>[
      MapEntry('EmiratesIdFront', _imageFile(draft.idFrontPath!)),
      MapEntry('EmiratesIdBack', _imageFile(draft.idBackPath!)),
      MapEntry('ChequePhoto', _imageFile(draft.chequeCopyPath!)),
      MapEntry('Signature', _imageFile(draft.signaturePath!)),
      if (draft.voucherPath != null) MapEntry('AcknowledgementVoucher', _imageFile(draft.voucherPath!)),
      if (draft.repPhotoPath != null) MapEntry('CollectorPhoto', _imageFile(draft.repPhotoPath!)),
      for (final path in draft.supportingDocPaths) MapEntry('SupportingDocuments', _imageFile(path)),
    ];

    final formData = FormData()
      ..fields.addAll(fields)
      ..files.addAll(files);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.chequeCollection(cheque.id),
        data: formData,
      );
      return CollectionRecordModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<List<CollectionSummaryModel>> getAll() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.collections);
      return response.data!.map((json) => CollectionSummaryModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<CollectionRecordModel> getByChequeId(String chequeId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.collectionByChequeId(chequeId));
      return CollectionRecordModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  /// Byte-sniffing on the server rejects a mismatched declared type, so the
  /// `Content-Type` here must actually match the file's real format, not
  /// just its extension — every capture path in this app already writes
  /// real JPEG/PNG bytes (`ImageCaptureService`, the signature PNG export),
  /// so trusting the extension is safe here.
  MultipartFile _imageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    final mediaType = switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };
    return MultipartFile.fromFileSync(path, contentType: mediaType);
  }
}
