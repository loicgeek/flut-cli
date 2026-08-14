import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../api/api_client.dart';
import '../api/interceptors/auth_interceptor.dart';
import '../api/interceptors/connectivity_interceptor.dart';
import '../api/interceptors/retry_interceptor.dart';
import '../config/app_config.dart';
import '../router/app_router.dart';
import '../storage/secure_storage.dart';

// ignore: non_constant_identifier_names
final sl = GetIt.instance;

Future<void> setupServiceLocator(AppConfig config) async {
  // ── Config ─────────────────────────────────────────────────────────────────
  sl.registerSingleton<AppConfig>(config);

  // ── Core ───────────────────────────────────────────────────────────────────
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerSingleton<SecureStorage>(SecureStorage(sl()));
  sl.registerSingleton<Connectivity>(Connectivity());

  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerSingleton<AuthInterceptor>(AuthInterceptor(sl()));
  sl.registerSingleton<RetryInterceptor>(RetryInterceptor());
  sl.registerSingleton<ConnectivityInterceptor>(ConnectivityInterceptor(sl()));
  sl.registerSingleton<Dio>(buildDioClient(config, sl(), sl(), sl()));

  // ── Router ─────────────────────────────────────────────────────────────────
  sl.registerSingleton<AppRouter>(AppRouter());

  // ── Features ───────────────────────────────────────────────────────────────
  // Repositories  -> registerSingleton
  // Cubits/Blocs  -> registerFactory   (new instance per screen)
  //
  // Example:
  // sl.registerSingleton<AuthRepository>(AuthRepository(sl()));
  // sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
}

