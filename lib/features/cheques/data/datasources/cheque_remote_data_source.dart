import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../domain/entities/cheque_audit_entry.dart';
import '../models/cheque_model.dart';

/// Result of `GET /cheques`, before it's wrapped into the domain's
/// `ChequePage` (kept here rather than importing the domain entity so this
/// datasource only ever deals in [ChequeModel]).
typedef ChequeListResponse = ({List<ChequeModel> items, int totalCount, int page, int pageSize});

abstract class ChequeRemoteDataSource {
  Future<ChequeListResponse> getCheques({String? search, String? status, String? paymentType, int? page, int? pageSize});
  Future<ChequeModel> getChequeById(String id);
  Future<List<ChequeAuditEntry>> getChequeAudit(String id);
}

class ChequeRemoteDataSourceImpl implements ChequeRemoteDataSource {
  const ChequeRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ChequeListResponse> getCheques({
    String? search,
    String? status,
    String? paymentType,
    int? page,
    int? pageSize,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.cheques,
        queryParameters: {
          if (search != null) 'search': search,
          if (status != null) 'status': status,
          if (paymentType != null) 'paymentType': paymentType,
          if (page != null) 'page': page,
          if (pageSize != null) 'pageSize': pageSize,
        },
      );
      final data = response.data!;
      return (
        items: (data['items'] as List<dynamic>)
            .map((json) => ChequeModel.fromJson(json as Map<String, dynamic>))
            .toList(),
        totalCount: data['totalCount'] as int,
        page: data['page'] as int,
        pageSize: data['pageSize'] as int,
      );
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<ChequeModel> getChequeById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.chequeDetail(id));
      return ChequeModel.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }

  @override
  Future<List<ChequeAuditEntry>> getChequeAudit(String id) async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.chequeAudit(id));
      return response.data!
          .map(
            (json) => ChequeAuditEntry(
              actor: (json as Map<String, dynamic>)['actor'] as String,
              action: json['action'] as String,
              timestamp: DateTime.parse(json['timestamp'] as String),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }
}
