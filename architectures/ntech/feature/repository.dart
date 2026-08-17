import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/{{name}}_model.dart';

class {{Pascal}}Repository {
  const {{Pascal}}Repository(this._dio);
  final Dio _dio;

  Future<List<{{Pascal}}Model>> get{{Pascal}}List() async {
    try {
      final response = await _dio.get(ApiEndpoints.{{name}}s);
      return (response.data as List)
          .map((e) => {{Pascal}}Model.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

