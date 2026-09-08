import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../domain/entities/vendor.dart';
import '../models/vendor_model.dart';

/// `GET /vendors/available-for-collection` — VRM role only server-side
/// (a non-VRM account gets a `ForbiddenException` via [ApiErrorParser]).
abstract class VendorRemoteDataSource {
  Future<List<Vendor>> getAvailableForCollection();
}

class VendorRemoteDataSourceImpl implements VendorRemoteDataSource {
  const VendorRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<VendorModel>> getAvailableForCollection() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.vendorsAvailableForCollection);
      return response.data!.map((json) => VendorModel.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiErrorParser.parse(e);
    }
  }
}
