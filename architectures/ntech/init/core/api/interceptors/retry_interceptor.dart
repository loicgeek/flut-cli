import 'dart:math' as math;
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  RetryInterceptor({this.maxRetries = 3, this.baseDelayMs = 500});
  final int maxRetries;
  final int baseDelayMs;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) { handler.next(err); return; }
    final attempt = (err.requestOptions.extra['_retry'] as int?) ?? 0;
    if (attempt >= maxRetries) { handler.next(err); return; }

    await Future<void>.delayed(Duration(
      milliseconds: baseDelayMs * math.pow(2, attempt).toInt()
          + math.Random().nextInt(200),
    ));
    err.requestOptions.extra['_retry'] = attempt + 1;
    try {
      handler.resolve(await Dio().fetch(err.requestOptions));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException e) {
    final s = e.response?.statusCode;
    return e.type == DioExceptionType.connectionTimeout  ||
           e.type == DioExceptionType.receiveTimeout     ||
           e.type == DioExceptionType.sendTimeout        ||
           e.type == DioExceptionType.connectionError    ||
           (s != null && s >= 500);
  }
}

