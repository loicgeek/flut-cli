import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  const SecureStorage(this._storage);
  final FlutterSecureStorage _storage;

  Future<String?> get accessToken  => _storage.read(key: 'access_token');
  Future<String?> get refreshToken => _storage.read(key: 'refresh_token');

  Future<void> saveTokens({required String access, required String refresh}) =>
      Future.wait([
        _storage.write(key: 'access_token',  value: access),
        _storage.write(key: 'refresh_token', value: refresh),
      ]);

  Future<void> clear() => _storage.deleteAll();
}

