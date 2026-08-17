import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/{{name}}_model.dart';

/// Contract for the remote source, so the repository can be tested against a
/// fake and a cache/local source can be swapped in later.
abstract interface class {{Pascal}}RemoteDataSource {
  Future<List<{{Pascal}}Model>> fetch{{Pascal}}List();
}

class {{Pascal}}RemoteDataSourceImpl implements {{Pascal}}RemoteDataSource {
  const {{Pascal}}RemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<{{Pascal}}Model>> fetch{{Pascal}}List() async {
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
