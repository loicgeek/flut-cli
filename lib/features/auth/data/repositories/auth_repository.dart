import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/auth_model.dart';

class AuthRepository {
  const AuthRepository(this._dio);
  final Dio _dio;

  Future<List<AuthModel>> getAuthList() async {
    try {
      final response = await _dio.get(ApiEndpoints.auths);
      return (response.data as List)
          .map((e) => AuthModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
