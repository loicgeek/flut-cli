import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/user_profile_model.dart';

class UserProfileRepository {
  const UserProfileRepository(this._dio);
  final Dio _dio;

  Future<List<UserProfileModel>> getUserProfileList() async {
    try {
      final response = await _dio.get(ApiEndpoints.user_profiles);
      return (response.data as List)
          .map((e) => UserProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
