import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final SecureStorage _storage;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _queue = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) { handler.next(err); return; }

    if (_isRefreshing) { _queue.add((options: err.requestOptions, handler: handler)); return; }
    _isRefreshing = true;

    try {
      final refresh = await _storage.refreshToken;
      if (refresh == null) { await _storage.clear(); handler.next(err); return; }

      final freshDio = Dio(BaseOptions(baseUrl: err.requestOptions.baseUrl));
      final res      = await freshDio.post('/auth/refresh', data: {'refresh_token': refresh});
      final newAccess  = res.data['access_token']  as String;
      final newRefresh = res.data['refresh_token'] as String? ?? refresh;

      await _storage.saveTokens(access: newAccess, refresh: newRefresh);
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      handler.resolve(await freshDio.fetch(err.requestOptions));

      for (final p in _queue) {
        p.options.headers['Authorization'] = 'Bearer $newAccess';
        p.handler.resolve(await freshDio.fetch(p.options));
      }
    } catch (_) {
      await _storage.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
      _queue.clear();
    }
  }
}

