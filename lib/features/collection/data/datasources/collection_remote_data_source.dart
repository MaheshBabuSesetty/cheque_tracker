import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/utils/image_compressor.dart';
import '../../domain/entities/collection_draft.dart';
import 'bulk_collection_flag.dart';
import '../models/collection_record_model.dart';
import '../models/collection_summary_model.dart';

abstract class CollectionRemoteDataSource {
  Future<List<CollectionRecordModel>> submit(CollectionDraft draft);
  Future<List<CollectionSummaryModel>> getAll();
  Future<CollectionRecordModel> getByChequeId(String chequeId);
}

/// Submits a collection in one atomic multipart request —
/// `POST /cheques/bulk/collection` — covering every cheque (one photo per
/// cheque) with the server-side SIGNED → ISSUED transition of all of them,
/// all-or-nothing. When the server has multi-cheque collection switched off
/// (see [BulkCollectionFlag]), or switches it off mid-session, it falls back
/// to one `POST /cheques/{chequeId}/collection` per cheque instead, which
/// is *not* atomic: a failure partway leaves the earlier cheques collected.
class CollectionRemoteDataSourceImpl implements CollectionRemoteDataSource {
  const CollectionRemoteDataSourceImpl(this._dio, this._bulkFlag);

  final Dio _dio;
  final BulkCollectionFlag _bulkFlag;

  static const _bulkDisabledCode = 'BULK_COLLECTION_DISABLED';

  @override
  Future<List<CollectionRecordModel>> submit(CollectionDraft draft) async {
    if (await _bulkFlag.isEnabled()) {
      try {
        return await _submitBulk(draft);
      } on ApiException catch (e) {
        if (e.code != _bulkDisabledCode) rethrow;
        // Switched off between the flag read and now.
        _bulkFlag.markDisabled();
      }
    }
    return _submitOneByOne(draft);
  }

  /// Fields and shared files common to the bulk request and every one-by-one
  /// request — not the voucher, which can differ per cheque. Nationality comes from the Emirates ID scan when it read one;
  /// the expiry date is no longer read by the scan, and the API accepts it
  /// empty (as it does an empty nationality) — the keys are sent anyway.
  Future<FormData> _sharedForm(CollectionDraft draft) async {
    final idScan = draft.idScan;
    final fields = <MapEntry<String, String>>[
      MapEntry('CollectorName', draft.repName.trim()),
      MapEntry('CollectorNationality', idScan?.nationality?.trim() ?? ''),
      const MapEntry('CollectorEidExpiryDate', ''),
    ];

    final mobileDigits = draft.repMobile.replaceAll(RegExp(r'\D'), '');
    if (mobileDigits.isNotEmpty) fields.add(MapEntry('CollectorMobile', '+971 $mobileDigits'));
    if (idScan != null && idScan.idNumber.isNotEmpty) fields.add(MapEntry('CollectorEmiratesId', idScan.idNumber));

    // `SupportingDocuments` must be repeated under the identical field name
    // for each file, not `SupportingDocuments[0]`/`[1]` — `FormData.files`
    // (a list of entries) supports that natively.
    final files = <MapEntry<String, MultipartFile>>[
      MapEntry('EmiratesIdFront', await _imageFile(draft.idFrontPath!)),
      MapEntry('EmiratesIdBack', await _imageFile(draft.idBackPath!)),
      MapEntry('Signature', await _imageFile(draft.signaturePath!)),
      for (final path in draft.supportingDocPaths) MapEntry('SupportingDocuments', await _imageFile(path)),
    ];

    return FormData()
      ..fields.addAll(fields)
      ..files.addAll(files);
  }

  Future<List<CollectionRecordModel>> _submitBulk(CollectionDraft draft) async {
    final formData = await _sharedForm(draft);
    // The shared voucher goes once at the top level; the server gives it to
    // every cheque that didn't send its own `Items[i].AcknowledgementVoucher`.
    if (draft.voucherPath != null) {
      formData.files.add(MapEntry('AcknowledgementVoucher', await _imageFile(draft.voucherPath!)));
    }
    // Each cheque is flat fields with the index in the name, from 0 with no
    // gaps (`Items` as a JSON string is ignored by the server and 400s). Its
    // own `ChequePhoto` (and voucher, if it has one) travels with it, so an
    // image can never be paired with the wrong cheque.
    for (var i = 0; i < draft.cheques.length; i++) {
      final entry = draft.cheques[i];
      formData.fields.add(MapEntry('Items[$i].ChequeId', entry.cheque.id));
      formData.files.add(MapEntry('Items[$i].ChequePhoto', await _imageFile(entry.photoPath)));
      if (entry.voucherPath != null) {
        formData.files.add(MapEntry('Items[$i].AcknowledgementVoucher', await _imageFile(entry.voucherPath!)));
      }
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(ApiEndpoints.chequesBulkCollection, data: formData);
      return (response.data!['collections'] as List<dynamic>)
          .map((json) => CollectionRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  Future<List<CollectionRecordModel>> _submitOneByOne(CollectionDraft draft) async {
    final records = <CollectionRecordModel>[];
    for (final entry in draft.cheques) {
      // A `FormData` can't be sent twice, so each request builds its own.
      final formData = await _sharedForm(draft);
      formData.files.add(MapEntry('ChequePhoto', await _imageFile(entry.photoPath)));
      // Same pick the bulk endpoint makes: the cheque's own voucher, else
      // the shared one, else none.
      final voucherPath = entry.voucherPath ?? draft.voucherPath;
      if (voucherPath != null) {
        formData.files.add(MapEntry('AcknowledgementVoucher', await _imageFile(voucherPath)));
      }
      try {
        final response = await _dio.post<Map<String, dynamic>>(
          ApiEndpoints.chequeCollection(entry.cheque.id),
          data: formData,
        );
        records.add(CollectionRecordModel.fromJson(response.data!));
      } on DioException catch (e) {
        // Cheques already collected stay collected; the caller works out
        // which by checking each cheque's status.
        throw ApiErrorParser.parse(e);
      }
    }
    return records;
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

  /// Reads [path], shrinks it for upload (see [ImageCompressor]) — the PNG
  /// signature is sent as is — and declares the content type of the bytes
  /// actually sent: the server byte-sniffs and rejects a mismatched declared
  /// type (and `application/octet-stream`).
  Future<MultipartFile> _imageFile(String path) async {
    final isPng = path.toLowerCase().endsWith('.png');
    final bytes = isPng ? await File(path).readAsBytes() : await ImageCompressor.compressForUpload(path);
    return MultipartFile.fromBytes(
      bytes,
      filename: path.split(Platform.pathSeparator).last,
      contentType: _sniffMediaType(bytes),
    );
  }

  static MediaType _sniffMediaType(Uint8List bytes) {
    if (bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50) return MediaType('image', 'png');
    if (bytes.length >= 12 && bytes[0] == 0x52 && bytes[8] == 0x57 && bytes[9] == 0x45) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
