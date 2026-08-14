import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../../error/failures.dart';

class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this._connectivity);
  final Connectivity _connectivity;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final results = await _connectivity.checkConnectivity();
    if (results.every((r) => r == ConnectivityResult.none)) {
      handler.reject(DioException(
        requestOptions: options,
        error: AppFailure.noInternet(),
        type: DioExceptionType.connectionError,
      ));
      return;
    }
    handler.next(options);
  }
}

