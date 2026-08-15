import 'package:dio/dio.dart';

import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/{{name}}_model.dart';
import '../services/{{name}}_service.dart';

class {{Pascal}}Repository {
  const {{Pascal}}Repository(this._service);

  /// The service handles multi-source orchestration.
  /// Add a Dio or remote data source here only if this repo also has
  /// its own direct network calls alongside the service.
  final {{Pascal}}Service _service;

  Future<List<{{Pascal}}Model>> get{{Pascal}}List() async {
    try {
      return await _service.get{{Pascal}}List();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}

