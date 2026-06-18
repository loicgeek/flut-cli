#!/usr/bin/env bash
# =============================================================================
#  flut — Flutter project scaffold CLI
#
#  Usage:
#    flut init                                  Init full lib/ scaffold + install packages
#    flut feature <n>                        Add a feature with Cubit
#    flut feature <n> --bloc               Add a feature with Bloc
#    flut feature <n> --service            Add a feature with a Service layer
#    flut feature <n> --bloc --service     Bloc + Service layer
#
#  Code generation: AutoRoute ONLY.
#  Models      → plain Dart class, manual fromJson/toJson
#  State       → plain sealed class
#  DI          → manual GetIt registration (no injectable)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${CYAN}  ->  ${RESET} $1"; }
log_success() { echo -e "${GREEN}  ok  ${RESET} $1"; }
log_warning() { echo -e "${YELLOW}  !!  ${RESET} $1"; }
log_error()   { echo -e "${RED}  xx  ${RESET} $1"; }
log_section() { echo -e "\n${BOLD}${CYAN}>> $1${RESET}"; }

mkf() {
  local path="$1" content="$2"
  mkdir -p "$(dirname "$path")"
  if [[ -f "$path" ]]; then
    log_warning "exists - skipped: $path"
  else
    printf '%s' "$content" > "$path"
    log_success "$path"
  fi
}

mkd() { mkdir -p "$1"; log_info "dir: $1"; }

to_pascal() {
  echo "$1" | awk -F'_' '{
    result=""
    for(i=1; i<=NF; i++) {
      result = result toupper(substr($i,1,1)) substr($i,2)
    }
    print result
  }'
}

# ==============================================================================
#  COMMAND: init
# ==============================================================================
cmd_init() {
  log_section "Initializing Flutter scaffold"

  if [[ ! -f "pubspec.yaml" ]]; then
    log_error "pubspec.yaml not found. Run from project root."
    exit 1
  fi

  local L="lib"

  log_section "Directories"
  mkd "$L/core/config"
  mkd "$L/core/api/interceptors"
  mkd "$L/core/auth"
  mkd "$L/core/storage"
  mkd "$L/core/error"
  mkd "$L/core/bloc"
  mkd "$L/core/theme"
  mkd "$L/core/di"
  mkd "$L/core/router"
  mkd "$L/features"
  mkd "$L/shared/models"
  mkd "$L/shared/widgets"
  mkd "$L/shared/utils"
  mkd "assets/translations"
  mkd "assets/images"
  mkd "assets/icons"
  mkd "assets/lottie"

  log_section "Files"

  # --------------------------------------------------------------------------
  # Entry points
  # --------------------------------------------------------------------------
  # main.dart  →  default entry point for `flutter run` (dev flavor)
  # main_dev / main_staging / main_prod  →  explicit flavor targets for CI
  mkf "$L/main.dart" "import 'core/bootstrap.dart';
import 'core/config/app_config.dart';

// Default entry point — maps to the dev flavor.
// Use flavor-specific targets for CI / release builds:
//   flutter run -t lib/main_dev.dart
//   flutter run -t lib/main_staging.dart
//   flutter run -t lib/main_prod.dart
void main() => bootstrap(AppConfig.dev);
"

  mkf "$L/main_dev.dart" "import 'core/bootstrap.dart';
import 'core/config/app_config.dart';

void main() => bootstrap(AppConfig.dev);
"

  mkf "$L/main_staging.dart" "import 'core/bootstrap.dart';
import 'core/config/app_config.dart';

void main() => bootstrap(AppConfig.staging);
"

  mkf "$L/main_prod.dart" "import 'core/bootstrap.dart';
import 'core/config/app_config.dart';

void main() => bootstrap(AppConfig.prod);
"

  # --------------------------------------------------------------------------
  # app.dart
  # --------------------------------------------------------------------------
  mkf "$L/app.dart" "import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, required this.config});
  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = sl<AppRouter>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.config.appName,
      debugShowCheckedModeBanner: !widget.config.isProduction,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router.config(),
    );
  }
}
"

  # --------------------------------------------------------------------------
  # core/config/app_config.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/config/app_config.dart" "enum AppFlavor { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
    this.enableLogging = false,
  });

  final AppFlavor flavor;
  final String baseUrl;
  final String appName;
  final bool enableLogging;

  bool get isProduction  => flavor == AppFlavor.prod;
  bool get isDevelopment => flavor == AppFlavor.dev;

  static const dev = AppConfig(
    flavor: AppFlavor.dev,
    baseUrl: 'https://api.dev.example.com',
    appName: 'App (Dev)',
    enableLogging: true,
  );

  static const staging = AppConfig(
    flavor: AppFlavor.staging,
    baseUrl: 'https://api.staging.example.com',
    appName: 'App (Staging)',
    enableLogging: true,
  );

  static const prod = AppConfig(
    flavor: AppFlavor.prod,
    baseUrl: 'https://api.example.com',
    appName: 'App',
  );
}
"

  # --------------------------------------------------------------------------
  # core/bootstrap.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/bootstrap.dart" "import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app.dart';
import 'bloc/app_bloc_observer.dart';
import 'config/app_config.dart';
import 'di/service_locator.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await EasyLocalization.ensureInitialized();

  Bloc.observer = AppBlocObserver(enableLogging: config.enableLogging);

  await setupServiceLocator(config);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: App(config: config),
    ),
  );
}
"

  # --------------------------------------------------------------------------
  # core/custom_transition_builders.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/custom_transition_builders.dart" "import 'package:flutter/material.dart';

// Build one transition builder for all routes.
// Swap the return statement to change the global transition style.
RouteTransitionsBuilder get customTransitionBuilder =>
    (context, animation, secondaryAnimation, child) {
      // Uncomment to disable all transitions:
      // return child;
      return FadeTransition(opacity: animation, child: child);
    };
"

  # --------------------------------------------------------------------------
  # core/di/service_locator.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/di/service_locator.dart" "import 'package:connectivity_plus/connectivity_plus.dart';
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
"

  # --------------------------------------------------------------------------
  # core/router/app_router.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/router/app_router.dart" "import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    // TODO: add routes
    // AutoRoute(page: LoginRoute.page, initial: true),
  ];
}
"

  # --------------------------------------------------------------------------
  # core/api/api_client.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/api/api_client.dart" "import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

Dio buildDioClient(
  AppConfig config,
  AuthInterceptor auth,
  RetryInterceptor retry,
  ConnectivityInterceptor connectivity,
) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    connectivity,
    auth,
    retry,
    if (config.enableLogging)
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        error: true,
        compact: false,
      ),
  ]);

  return dio;
}
"

  # --------------------------------------------------------------------------
  # core/api/api_endpoints.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/api/api_endpoints.dart" "abstract final class ApiEndpoints {
  // ── Auth ───────────────────────────────────────────────────────────────────
  static const login   = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout  = '/auth/logout';

  // Add endpoints by domain below
}
"

  # --------------------------------------------------------------------------
  # core/api/interceptors
  # --------------------------------------------------------------------------
  mkf "$L/core/api/interceptors/auth_interceptor.dart" "import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);
  final SecureStorage _storage;

  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})> _queue = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer \$token';
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
      err.requestOptions.headers['Authorization'] = 'Bearer \$newAccess';
      handler.resolve(await freshDio.fetch(err.requestOptions));

      for (final p in _queue) {
        p.options.headers['Authorization'] = 'Bearer \$newAccess';
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
"

  mkf "$L/core/api/interceptors/retry_interceptor.dart" "import 'dart:math' as math;
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
"

  mkf "$L/core/api/interceptors/connectivity_interceptor.dart" "import 'package:connectivity_plus/connectivity_plus.dart';
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
"

  # --------------------------------------------------------------------------
  # core/storage/secure_storage.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/storage/secure_storage.dart" "import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
"

  # --------------------------------------------------------------------------
  # core/error
  # --------------------------------------------------------------------------
  mkf "$L/core/error/failures.dart" "class AppFailure implements Exception {
  const AppFailure._({required this.userMessage, this.debugMessage});
  final String userMessage;
  final String? debugMessage;

  factory AppFailure.noInternet() => const AppFailure._(userMessage: 'Pas de connexion internet.');
  factory AppFailure.timeout() => const AppFailure._(userMessage: 'La requete a expire. Reessayez.');
  factory AppFailure.unauthorized() => const AppFailure._(userMessage: 'Session expiree. Reconnectez-vous.');
  factory AppFailure.forbidden() => const AppFailure._(userMessage: 'Acces refuse.');
  factory AppFailure.notFound() => const AppFailure._(userMessage: 'Ressource introuvable.');
  factory AppFailure.serverError({required int code, String? message}) => AppFailure._(
        userMessage: 'Erreur serveur. Reessayez plus tard.',
        debugMessage: 'HTTP \$code - \$message',
      );
  factory AppFailure.validation({required Map<String, List<String>> errors}) => AppFailure._(
        userMessage: errors.values.expand((e) => e).join('\n'),
      );
  factory AppFailure.unexpected({String? message}) => AppFailure._(
        userMessage: 'Une erreur inattendue est survenue.',
        debugMessage: message,
      );

  @override
  String toString() => 'AppFailure(\$userMessage | debug: \$debugMessage)';
}
"

  mkf "$L/core/error/exception_mapper.dart" "import 'package:dio/dio.dart';
import 'failures.dart';

AppFailure mapDioExceptionToFailure(DioException e) {
  if (e.error is AppFailure) return e.error as AppFailure;

  return switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout    ||
    DioExceptionType.sendTimeout       => AppFailure.timeout(),
    DioExceptionType.connectionError   => AppFailure.noInternet(),
    DioExceptionType.badResponse       => _fromResponse(e.response),
    _                                  => AppFailure.unexpected(message: e.message),
  };
}

AppFailure _fromResponse(Response? response) {
  final status = response?.statusCode ?? 0;
  final data   = response?.data;
  return switch (status) {
    401 => AppFailure.unauthorized(),
    403 => AppFailure.forbidden(),
    404 => AppFailure.notFound(),
    422 => AppFailure.validation(errors: _parseErrors(data)),
    _   => AppFailure.serverError(code: status, message: _parseMessage(data)),
  };
}

Map<String, List<String>> _parseErrors(dynamic data) {
  if (data is! Map<String, dynamic>) return {};
  final e = data['errors'];
  if (e is! Map<String, dynamic>) return {};
  return e.map((k, v) => MapEntry(k, (v as List).map((x) => x.toString()).toList()));
}

String? _parseMessage(dynamic d) =>
    d is Map<String, dynamic> ? d['message'] as String? : null;
"

  # --------------------------------------------------------------------------
  # core/auth/auth_guard.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/auth/auth_guard.dart" "import 'package:auto_route/auto_route.dart';
import '../di/service_locator.dart';
import '../storage/secure_storage.dart';
// import '../../features/auth/presentation/screens/login_screen.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final token = await sl<SecureStorage>().accessToken;
    if (token != null) {
      resolver.next(true);
    } else {
      // router.replace(const LoginRoute());
    }
  }
}
"

  # --------------------------------------------------------------------------
  # core/bloc/app_bloc_observer.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/bloc/app_bloc_observer.dart" "import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver({required this.enableLogging});
  final bool enableLogging;

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> t,
  ) {
    super.onTransition(bloc, t);
    if (enableLogging) {
      Logger().d(
        '[\${bloc.runtimeType}] \${t.event.runtimeType} -> \${t.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stack) {
    Logger().e('[\${bloc.runtimeType}]', error: error, stackTrace: stack);
    super.onError(bloc, error, stack);
  }
}
"

  # --------------------------------------------------------------------------
  # core/theme/app_theme.dart
  # --------------------------------------------------------------------------
  mkf "$L/core/theme/app_theme.dart" "import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF0057FF),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111111),
        ),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF0057FF),
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
      );
}
"

  # --------------------------------------------------------------------------
  # shared/widgets
  # --------------------------------------------------------------------------
  mkf "$L/shared/widgets/loading_shimmer.dart" "import 'package:flutter/material.dart';

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.height, this.width, this.radius});
  final double? height;
  final double? width;
  final double? radius;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          height: widget.height ?? 16,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.radius ?? 8),
          ),
        ),
      );
}
"

  mkf "$L/shared/widgets/empty_state.dart" "import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon, this.onAction, this.actionLabel});
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon ?? Icons.inbox_outlined, size: 64,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline)),
              if (onAction != null && actionLabel != null) ...[
                const SizedBox(height: 24),
                FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}
"

  mkf "$L/shared/widgets/error_state.dart" "import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(message ?? 'Une erreur est survenue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reessayer'),
                ),
              ],
            ],
          ),
        ),
      );
}
"

  # --------------------------------------------------------------------------
  # Translations
  # --------------------------------------------------------------------------
  mkf "assets/translations/fr.json" '{
  "common": {
    "loading": "Chargement...",
    "retry": "Reessayer",
    "cancel": "Annuler",
    "confirm": "Confirmer",
    "save": "Enregistrer",
    "delete": "Supprimer",
    "close": "Fermer"
  },
  "errors": {
    "no_internet": "Pas de connexion internet.",
    "session_expired": "Session expiree. Reconnectez-vous.",
    "unexpected": "Une erreur inattendue est survenue.",
    "server": "Erreur serveur. Reessayez plus tard.",
    "timeout": "La requete a expire. Reessayez.",
    "not_found": "Ressource introuvable.",
    "forbidden": "Acces refuse."
  }
}
'

  mkf "assets/translations/en.json" '{
  "common": {
    "loading": "Loading...",
    "retry": "Retry",
    "cancel": "Cancel",
    "confirm": "Confirm",
    "save": "Save",
    "delete": "Delete",
    "close": "Close"
  },
  "errors": {
    "no_internet": "No internet connection.",
    "session_expired": "Session expired. Please log in again.",
    "unexpected": "An unexpected error occurred.",
    "server": "Server error. Please try again later.",
    "timeout": "Request timed out. Please retry.",
    "not_found": "Resource not found.",
    "forbidden": "Access denied."
  }
}
'

  # --------------------------------------------------------------------------
  # IDE — VS Code launch configurations
  # --------------------------------------------------------------------------
  log_section "IDE settings"

  mkd ".vscode"
  mkf ".vscode/launch.json" '{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Dev",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "flutterMode": "debug"
    },
    {
      "name": "Dev (profile)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_dev.dart",
      "flutterMode": "profile"
    },
    {
      "name": "Staging",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_staging.dart",
      "flutterMode": "debug"
    },
    {
      "name": "Prod",
      "request": "launch",
      "type": "dart",
      "program": "lib/main_prod.dart",
      "flutterMode": "release"
    }
  ]
}
'

  # --------------------------------------------------------------------------
  # IDE — Android Studio / IntelliJ run configurations
  # --------------------------------------------------------------------------
  mkd ".idea/runConfigurations"

  mkf ".idea/runConfigurations/Dev.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Dev" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
    <option name="additionalArgs" value="" />
    <method v="2" />
  </configuration>
</component>
'

  mkf ".idea/runConfigurations/Dev_profile.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Dev (profile)" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
    <option name="additionalArgs" value="--profile" />
    <method v="2" />
  </configuration>
</component>
'

  mkf ".idea/runConfigurations/Staging.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Staging" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_staging.dart" />
    <option name="additionalArgs" value="" />
    <method v="2" />
  </configuration>
</component>
'

  mkf ".idea/runConfigurations/Prod.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Prod" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_prod.dart" />
    <option name="additionalArgs" value="--release" />
    <method v="2" />
  </configuration>
</component>
'

  # --------------------------------------------------------------------------
  # flutter pub add
  # --------------------------------------------------------------------------
  log_section "Installing packages"

  if ! command -v flutter &>/dev/null; then
    log_warning "flutter not found in PATH - skipping pub add."
    log_warning "Run manually:"
    _print_pub_cmds
    _print_success
    return
  fi

  local runtime=(
    flutter_bloc equatable get_it auto_route
    dio connectivity_plus pretty_dio_logger
    flutter_secure_storage easy_localization logger intl
  )
  local dev_pkgs=(build_runner auto_route_generator)

  log_info "Adding runtime packages..."
  flutter pub add "${runtime[@]}" || { log_error "pub add failed."; exit 1; }
  log_success "Runtime packages added."

  log_info "Adding dev packages..."
  flutter pub add --dev "${dev_pkgs[@]}" || { log_error "pub add --dev failed."; exit 1; }
  log_success "Dev packages added."

  _print_success
}

_print_pub_cmds() {
  echo ""
  echo "  flutter pub add \\"
  echo "    flutter_bloc equatable get_it auto_route \\"
  echo "    dio connectivity_plus pretty_dio_logger \\"
  echo "    flutter_secure_storage easy_localization logger intl"
  echo ""
  echo "  flutter pub add --dev build_runner auto_route_generator"
  echo ""
}

_print_success() {
  echo ""
  echo -e "${BOLD}${GREEN}  Scaffold ready.${RESET}"
  echo ""
  echo -e "${YELLOW}  Next steps:${RESET}"
  echo "    1. dart run build_runner build --delete-conflicting-outputs"
  echo "    2. Register features in lib/core/di/service_locator.dart"
  echo "    3. flut feature <name>"
  echo ""
}

# ==============================================================================
#  COMMAND: feature
# ==============================================================================
cmd_feature() {
  local name="${1:-}"
  local use_bloc=false
  local use_service=false

  # Parse all flags after the feature name
  shift || true
  for arg in "$@"; do
    case "$arg" in
      --bloc)    use_bloc=true ;;
      --service) use_service=true ;;
      *) log_error "Unknown flag: $arg"; echo "  Usage: flut feature <n> [--bloc] [--service]"; exit 1 ;;
    esac
  done

  if [[ -z "$name" ]]; then
    log_error "Feature name is required."
    echo "  Usage: flut feature <n> [--bloc] [--service]"
    exit 1
  fi

  if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Feature name must be snake_case."
    exit 1
  fi

  local pascal
  pascal=$(to_pascal "$name")
  local BASE="lib/features/$name"

  if [[ -d "$BASE" ]]; then
    log_error "Feature '$name' already exists."
    exit 1
  fi

  log_section "Feature: $name  ->  $pascal"

  mkd "$BASE/business_logic"
  mkd "$BASE/data/models"
  mkd "$BASE/data/repositories"
  mkd "$BASE/presentation/router"
  mkd "$BASE/presentation/screens"
  mkd "$BASE/presentation/widgets"

  if [[ "$use_service" == true ]]; then
    mkd "$BASE/data/services"
  fi

  # --------------------------------------------------------------------------
  # Model — plain Dart class, zero codegen
  # --------------------------------------------------------------------------
  mkf "$BASE/data/models/${name}_model.dart" "class ${pascal}Model {
  const ${pascal}Model({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  ${pascal}Model copyWith({
    String? id,
    // TODO: add fields
  }) {
    return ${pascal}Model(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${pascal}Model && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '${pascal}Model(id: \$id)';
}
"

  # --------------------------------------------------------------------------
  # Service layer (optional)
  # When --service: the Repository delegates to the Service.
  # The Service handles multi-source orchestration, caching, or transformation.
  # Without --service: the Repository handles data access directly.
  # --------------------------------------------------------------------------
  if [[ "$use_service" == true ]]; then
    mkf "$BASE/data/services/${name}_service.dart" "import '../models/${name}_model.dart';

/// ${pascal}Service handles data orchestration across multiple sources,
/// or any business logic that does not belong inside the repository itself.
///
/// Inject additional data sources (remote, local, cache) as constructor params.
///
/// Usage: the ${pascal}Repository delegates to this service.
class ${pascal}Service {
  const ${pascal}Service(
    // TODO: inject your data sources
    // this._remoteDataSource,
    // this._localDataSource,
  );

  Future<List<${pascal}Model>> get${pascal}List() async {
    // TODO: orchestrate sources, e.g. cache-first, merge, transform
    throw UnimplementedError();
  }
}
"
  fi

  # --------------------------------------------------------------------------
  # Repository
  # Bloc/Cubit always injects the Repository.
  # When --service, the Repository injects and delegates to the Service.
  # --------------------------------------------------------------------------
  if [[ "$use_service" == true ]]; then
    mkf "$BASE/data/repositories/${name}_repository.dart" "import 'package:dio/dio.dart';

import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/${name}_model.dart';
import '../services/${name}_service.dart';

class ${pascal}Repository {
  const ${pascal}Repository(this._service);

  /// The service handles multi-source orchestration.
  /// Add a Dio or remote data source here only if this repo also has
  /// its own direct network calls alongside the service.
  final ${pascal}Service _service;

  Future<List<${pascal}Model>> get${pascal}List() async {
    try {
      return await _service.get${pascal}List();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
"
  else
    mkf "$BASE/data/repositories/${name}_repository.dart" "import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/${name}_model.dart';

class ${pascal}Repository {
  const ${pascal}Repository(this._dio);
  final Dio _dio;

  Future<List<${pascal}Model>> get${pascal}List() async {
    try {
      final response = await _dio.get(ApiEndpoints.${name}s);
      return (response.data as List)
          .map((e) => ${pascal}Model.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
"
  fi

  # --------------------------------------------------------------------------
  # State — plain sealed class, zero codegen
  # --------------------------------------------------------------------------
  mkf "$BASE/business_logic/${name}_state.dart" "import '../data/models/${name}_model.dart';

sealed class ${pascal}State { const ${pascal}State(); }

final class ${pascal}Initial extends ${pascal}State { const ${pascal}Initial(); }
final class ${pascal}Loading extends ${pascal}State { const ${pascal}Loading(); }
final class ${pascal}Loaded  extends ${pascal}State {
  const ${pascal}Loaded(this.items);
  final List<${pascal}Model> items;
}
final class ${pascal}Error extends ${pascal}State {
  const ${pascal}Error(this.message);
  final String message;
}
"

  # --------------------------------------------------------------------------
  # Cubit or Bloc — always injects Repository
  # --------------------------------------------------------------------------
  if [[ "$use_bloc" == true ]]; then
    mkf "$BASE/business_logic/${name}_event.dart" "sealed class ${pascal}Event { const ${pascal}Event(); }

final class ${pascal}Load    extends ${pascal}Event { const ${pascal}Load(); }
final class ${pascal}Refresh extends ${pascal}Event { const ${pascal}Refresh(); }
// TODO: add events
"

    mkf "$BASE/business_logic/${name}_bloc.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${name}_event.dart';
import '${name}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc(this._repository) : super(const ${pascal}Initial()) {
    on<${pascal}Load>(_onLoad);
    on<${pascal}Refresh>(_onRefresh);
  }

  final ${pascal}Repository _repository;

  Future<void> _onLoad(${pascal}Load event, Emitter<${pascal}State> emit) async {
    emit(const ${pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      emit(${pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${pascal}Error(f.userMessage));
    }
  }

  Future<void> _onRefresh(${pascal}Refresh event, Emitter<${pascal}State> emit) async {
    try {
      final items = await _repository.get${pascal}List();
      emit(${pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${pascal}Error(f.userMessage));
    }
  }
}
"
  else
    mkf "$BASE/business_logic/${name}_cubit.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${name}_state.dart';

class ${pascal}Cubit extends Cubit<${pascal}State> {
  ${pascal}Cubit(this._repository) : super(const ${pascal}Initial());
  final ${pascal}Repository _repository;

  Future<void> load() async {
    emit(const ${pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      if (!isClosed) emit(${pascal}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(${pascal}Error(f.userMessage));
    }
  }
}
"
  fi

  # --------------------------------------------------------------------------
  # Feature router module
  # --------------------------------------------------------------------------
  local pkg_name="your_app"
  if [[ -f "pubspec.yaml" ]]; then
    local parsed
    parsed=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    [[ -n "$parsed" ]] && pkg_name="$parsed"
  fi

  mkf "$BASE/presentation/router/${name}_router_module.dart" "import 'package:auto_route/auto_route.dart';

import 'package:${pkg_name}/core/custom_transition_builders.dart';
import '../screens/${name}_screen.dart';

part '${name}_router_module.g.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/${name}/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class ${pascal}RouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        transitionsBuilder: customTransitionBuilder,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: ${pascal}Route.page),
        // TODO: add more routes for this feature
      ];
}
"

  # --------------------------------------------------------------------------
  # Screen
  # --------------------------------------------------------------------------
  local bl_type bl_provide bl_import bl_retry
  if [[ "$use_bloc" == true ]]; then
    bl_type="${pascal}Bloc"
    bl_import="${name}_bloc.dart"
    bl_provide="create: (_) => sl<${pascal}Bloc>()..add(const ${pascal}Load())"
    bl_retry="context.read<${pascal}Bloc>().add(const ${pascal}Refresh())"
  else
    bl_type="${pascal}Cubit"
    bl_import="${name}_cubit.dart"
    bl_provide="create: (_) => sl<${pascal}Cubit>()..load()"
    bl_retry="context.read<${pascal}Cubit>().load()"
  fi

  mkf "$BASE/presentation/screens/${name}_screen.dart" "import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/${bl_import}';
import '../../business_logic/${name}_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      ${bl_provide},
      child: const _${pascal}View(),
    );
  }
}

class _${pascal}View extends StatelessWidget {
  const _${pascal}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${name}.title'.tr())),
      body: BlocConsumer<${bl_type}, ${pascal}State>(
        listener: (context, state) {
          if (state is ${pascal}Error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          ${pascal}Initial() => const SizedBox.shrink(),
          ${pascal}Loading() => const Center(child: LoadingShimmer()),
          ${pascal}Error()   => ErrorState(
              message: (state as ${pascal}Error).message,
              onRetry: () => ${bl_retry},
            ),
          ${pascal}Loaded()  => _${pascal}List(
              items: (state as ${pascal}Loaded).items,
            ),
        },
      ),
    );
  }
}

class _${pascal}List extends StatelessWidget {
  const _${pascal}List({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: '${name}.empty'.tr());
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].id)),
      // TODO: build item UI
    );
  }
}
"

  # --------------------------------------------------------------------------
  # Post-generation checklist
  # --------------------------------------------------------------------------
  echo ""
  log_section "Checklist"

  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  if [[ "$use_service" == true ]]; then
    echo "     sl.registerSingleton<${pascal}Service>(${pascal}Service(/* data sources */));"
    echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  else
    echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  fi
  if [[ "$use_bloc" == true ]]; then
    echo "     sl.registerFactory<${pascal}Bloc>(() => ${pascal}Bloc(sl()));"
  else
    echo "     sl.registerFactory<${pascal}Cubit>(() => ${pascal}Cubit(sl()));"
  fi

  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     static const ${name}s = '/${name}s';"

  echo ""
  echo -e "  ${YELLOW}3. lib/core/router/app_router.dart${RESET}"
  echo "     AutoRoute(page: ${pascal}Route.page),"

  echo ""
  echo -e "  ${YELLOW}4. assets/translations/fr.json  &  en.json${RESET}"
  echo "     \"${name}\": { \"title\": \"...\", \"empty\": \"...\" }"

  echo ""
  echo -e "  ${YELLOW}5. presentation/router/${name}_router_module.dart${RESET}"
  echo "     Wire ${pascal}RouterModule into app_router.dart as a child route if needed."

  echo ""
  echo -e "  ${YELLOW}6. Code generation${RESET}"
  echo "     dart run build_runner build --delete-conflicting-outputs"

  echo ""
  echo -e "${BOLD}${GREEN}  Feature '$name' ready.${RESET}"
  echo ""
}

# ==============================================================================
#  COMMAND: upgrade
# ==============================================================================

# Resolve the real directory of this script, following symlinks.
# Works on macOS (no readlink -f) and Linux.
_resolve_install_dir() {
  local source="${BASH_SOURCE[0]}"
  local dir
  while [[ -L "$source" ]]; do
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    # Handle relative symlinks
    [[ "$source" != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}

cmd_upgrade() {
  local INSTALL_DIR
  INSTALL_DIR="$(_resolve_install_dir)"

  log_section "Upgrading flut-cli"
  log_info "Install dir: $INSTALL_DIR"

  if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    log_error "Cannot upgrade: $INSTALL_DIR is not a git repository."
    log_error "Re-install with: curl -fsSL https://raw.githubusercontent.com/kehitaa/flut-cli/main/install.sh | bash"
    exit 1
  fi

  # Detect the default remote branch (main or master)
  local remote_branch
  remote_branch=$(git -C "$INSTALL_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null     | sed 's|refs/remotes/origin/||') || remote_branch="main"

  local before
  before=$(git -C "$INSTALL_DIR" rev-parse --short HEAD)

  # Warn if local changes exist (they will be discarded)
  local dirty
  dirty=$(git -C "$INSTALL_DIR" status --porcelain 2>/dev/null)
  if [[ -n "$dirty" ]]; then
    log_warning "Local changes in $INSTALL_DIR will be discarded:"
    git -C "$INSTALL_DIR" status --short
    echo ""
  fi

  log_info "Fetching from origin..."
  git -C "$INSTALL_DIR" fetch origin "$remote_branch" || {
    log_error "git fetch failed. Check your connection."
    exit 1
  }

  log_info "Resetting to origin/$remote_branch..."
  git -C "$INSTALL_DIR" reset --hard "origin/$remote_branch"

  local after
  after=$(git -C "$INSTALL_DIR" rev-parse --short HEAD)

  echo ""
  if [[ "$before" == "$after" ]]; then
    log_success "Already up to date ($after)."
  else
    log_success "Updated $before -> $after"
    echo ""
    log_info "Changelog:"
    git -C "$INSTALL_DIR" log --oneline "${before}..${after}"
  fi
  echo ""
}

# ==============================================================================
#  COMMAND: check — Architecture Audit
# ==============================================================================

cmd_check() {
  local warnings=0
  local errors=0

  # ── helpers for internal check functions ────────────────────────────────────
  # Note: use $((var + 1)) instead of var=$((var + 1)) because with set -e,
  # errors=$((errors + 1)) exits the script when errors is 0 (returns old value 0 = falsy).
  _check_pass() { log_success "$1"; }
  _check_err()  { errors=$((errors + 1)); log_error "$1"; }
  _check_warn() { warnings=$((warnings + 1)); log_warning "$1"; }

  # ── Check 1: Feature structure ─────────────────────────────────────────────
  _check_1_feature_structure() {
    local features=()
    for f in lib/features/*/; do
      [[ -d "$f" ]] || continue
      features+=("$(basename "$f")")
    done

    if [[ ${#features[@]} -eq 0 ]]; then
      log_info "No features found — skipping feature structure check."
      return 0
    fi

    local total_err=0
    for feat in "${features[@]}"; do
      local missing=()
      [[ -d "lib/features/$feat/business_logic"       ]] || missing+=("business_logic")
      [[ -d "lib/features/$feat/data"                 ]] || missing+=("data")
      [[ -d "lib/features/$feat/data/models"          ]] || missing+=("data/models")
      [[ -d "lib/features/$feat/data/repositories"    ]] || missing+=("data/repositories")
      [[ -d "lib/features/$feat/presentation"         ]] || missing+=("presentation")
      [[ -d "lib/features/$feat/presentation/screens" ]] || missing+=("presentation/screens")
      [[ -d "lib/features/$feat/presentation/router"  ]] || missing+=("presentation/router")
      [[ -d "lib/features/$feat/presentation/widgets" ]] || missing+=("presentation/widgets")

      if [[ ${#missing[@]} -gt 0 ]]; then
        _check_err "$feat — missing required dir(s): ${missing[*]}"
        total_err=$((total_err + 1))
      fi
    done

    if [[ $total_err -eq 0 ]]; then
      _check_pass "Feature structure (${#features[@]} features)"
    fi
  }

  # ── Check 2: State is sealed ───────────────────────────────────────────────
  _check_2_sealed_states() {
    local files=()
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find lib/ -name '*_state.dart' -print0 2>/dev/null)

    local total=${#files[@]}
    local valid=0
    local err=0

    if [[ $total -eq 0 ]]; then
      log_info "No state files found — skipping sealed state check."
      return
    fi

    for f in "${files[@]}"; do
      if grep -q 'sealed class' "$f" 2>/dev/null; then
        valid=$((valid + 1))
      else
        _check_err "${f#lib/} — state file does not declare a sealed class"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Sealed states ($valid/$total valid)"
    fi
  }

  # ── Check 3: No banned codegen packages ────────────────────────────────────
  _check_3_banned_codegen() {
    if [[ ! -f "pubspec.yaml" ]]; then
      _check_warn "pubspec.yaml not found — cannot check for banned packages"
      return
    fi

    local err=0
    if grep -qE '^[[:space:]]*freezed[[:space:]]*$|freezed:' pubspec.yaml 2>/dev/null; then
      _check_warn "Banned package 'freezed' found in pubspec.yaml"
      err=$((err + 1))
    fi
    if grep -qE '^[[:space:]]*json_serializable[[:space:]]*$|json_serializable:' pubspec.yaml 2>/dev/null; then
      _check_warn "Banned package 'json_serializable' found in pubspec.yaml"
      err=$((err + 1))
    fi

    if [[ $err -eq 0 ]]; then
      _check_pass "No banned packages"
    fi
  }

  # ── Check 4: Layer boundaries ──────────────────────────────────────────────
  _check_4_layer_boundaries() {
    local files=()
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find lib/features/*/presentation -name '*.dart' -print0 2>/dev/null)

    if [[ ${#files[@]} -eq 0 ]]; then
      log_info "No presentation files found — skipping layer boundary check."
      return
    fi

    local err=0
    for f in "${files[@]}"; do
      local feat
      feat="$(echo "$f" | sed 's|lib/features/\([^/]*\).*|\1|')"
      local rel="${f#lib/}"
      if grep -qE "import.*data/" "$f" 2>/dev/null; then
        _check_err "$feat — $rel imports data/ directly"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Layer boundaries — no presentation files import data/ directly"
    fi
  }

  # ── Check 5: Router registration ───────────────────────────────────────────
  _check_5_router_registration() {
    local screens=()
    while IFS= read -r -d '' f; do
      screens+=("$f")
    done < <(find lib/features -path '*/presentation/screens/*.dart' -print0 2>/dev/null)

    if [[ ${#screens[@]} -eq 0 ]]; then
      log_info "No screens found — skipping router registration check."
      return
    fi

    if [[ ! -f "lib/core/router/app_router.dart" ]]; then
      _check_warn "lib/core/router/app_router.dart not found — cannot verify router registration"
      return
    fi

    local router_content
    router_content=$(cat "lib/core/router/app_router.dart" 2>/dev/null)
    local total=${#screens[@]}
    local registered=0
    local err=0

    for f in "${screens[@]}"; do
      local basename
      basename="$(basename "$f" .dart)"
      # AutoRoute converts auth_screen -> AuthRoute (replaceInRouteName: 'Screen,Route')
      # Convert snake_case to PascalCase (reusing to_pascal) then append Route
      local name_no_suffix
      name_no_suffix=$(echo "$basename" | sed 's/_screen$//' | sed 's/_route$//')
      local pascal
      pascal="$(to_pascal "$name_no_suffix")Route"

      if echo "$router_content" | grep -q "$pascal"; then
        registered=$((registered + 1))
      else
        local rel="${f#lib/}"
        _check_warn "$rel — may not be registered in app_router.dart (seeking: $pascal)"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Router registration ($registered/$total screens)"
    fi
  }

  # ── Check 6: DI registration ───────────────────────────────────────────────
  _check_6_di_registration() {
    if [[ ! -f "lib/core/di/service_locator.dart" ]]; then
      _check_warn "lib/core/di/service_locator.dart not found — skipping DI check"
      return
    fi

    local sl_content
    sl_content=$(cat "lib/core/di/service_locator.dart" 2>/dev/null)
    local err=0
    local total=0
    local matched=0

    # Find all sl.registerSingleton<...> and sl.registerFactory<...>
    local registrations=()
    while IFS= read -r line; do
      registrations+=("$line")
    done < <(echo "$sl_content" | grep -oE 'sl\.(registerSingleton|registerFactory)<[A-Za-z0-9_]+>' || true)

    total=${#registrations[@]}

    if [[ $total -eq 0 ]]; then
      log_info "No DI registrations found — skipping DI check."
      return
    fi

    for reg in "${registrations[@]}"; do
      local class_name
      class_name=$(echo "$reg" | sed 's/.*<//; s/>.*//')
      local file
      file=$(find lib/ -name "${class_name}.dart" -print -quit 2>/dev/null)
      if [[ -n "$file" ]]; then
        matched=$((matched + 1))
      else
        _check_warn "$class_name is registered in service_locator.dart but no corresponding file found"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "DI registration ($matched/$total registrations have matching files)"
    fi
  }

  # ── Check 7: Translation keys ──────────────────────────────────────────────
  _check_7_translation_keys() {
    if [[ ! -f "assets/translations/en.json" ]]; then
      _check_warn "assets/translations/en.json not found — skipping translation key check"
      return
    fi
    if [[ ! -f "assets/translations/fr.json" ]]; then
      _check_warn "assets/translations/fr.json not found — skipping translation key check"
      return
    fi

    local en_content fr_content
    en_content=$(cat "assets/translations/en.json" 2>/dev/null)
    fr_content=$(cat "assets/translations/fr.json" 2>/dev/null)

    local err=0
    local found=0

    # Find all tr('...') or tr("...") calls in Dart files
    local tr_keys=()
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      tr_keys+=("$key")
    done < <(grep -rohE "tr\\([\"']([^\"']+)[\"'']" --include='*.dart' lib/ 2>/dev/null | sed "s/tr(\"//; s/tr('//; s/\"$//; s/'$//; s/)$//" | sort -u || true)

    if [[ ${#tr_keys[@]} -eq 0 ]]; then
      log_info "No tr() calls found — skipping translation key check."
      return
    fi

    for key in "${tr_keys[@]}"; do
      local escaped
      escaped=$(echo "$key" | sed 's/\././g')
      found=$((found + 1))
      local in_en=0
      local in_fr=0

      if echo "$en_content" | grep -qF "\"$key\""; then
        in_en=1
      fi
      if echo "$fr_content" | grep -qF "\"$key\""; then
        in_fr=1
      fi

      if [[ $in_en -eq 0 ]] && [[ $in_fr -eq 0 ]]; then
        _check_warn "Translation key \"$key\" missing from both en.json and fr.json"
        err=$((err + 1))
      elif [[ $in_en -eq 0 ]]; then
        _check_warn "Translation key \"$key\" missing from en.json"
        err=$((err + 1))
      elif [[ $in_fr -eq 0 ]]; then
        _check_warn "Translation key \"$key\" missing from fr.json"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Translation keys ($found keys found in both en.json and fr.json)"
    fi
  }

  # ── Check 8: No orphaned generated files ───────────────────────────────────
  _check_8_orphaned_generated() {
    local gr_files=()
    while IFS= read -r -d '' f; do
      gr_files+=("$f")
    done < <(find lib/ -name '*.gr.dart' -print0 2>/dev/null)

    if [[ ${#gr_files[@]} -eq 0 ]]; then
      log_info "No .gr.dart files found — skipping orphaned generated file check."
      return
    fi

    local err=0
    for f in "${gr_files[@]}"; do
      local source
      source="${f%.gr.dart}.dart"
      if [[ ! -f "$source" ]]; then
        _check_warn "${f#lib/} — generated file exists but source ${source#lib/} has been deleted"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "No orphaned generated files (${#gr_files[@]} .gr.dart files)"
    fi
  }

  # ── Check 9: Cubit/Bloc convention ─────────────────────────────────────────
  _check_9_cubit_convention() {
    local cubit_files=()
    while IFS= read -r -d '' f; do
      cubit_files+=("$f")
    done < <(find lib/ \( -name '*_cubit.dart' -o -name '*_bloc.dart' \) -print0 2>/dev/null)

    if [[ ${#cubit_files[@]} -eq 0 ]]; then
      log_info "No Cubit/Bloc files found — skipping convention check."
      return
    fi

    local err=0
    local total=0
    local clean=0

    for f in "${cubit_files[@]}"; do
      total=$((total + 1))
      local content
      content=$(cat "$f" 2>/dev/null)
      # Check if file uses try/catch
      if echo "$content" | grep -qE 'catch\s*\('; then
        local rel="${f#lib/}"
        # Check if it catches AppFailure or generic Exception
        if echo "$content" | grep -q 'catch.*AppFailure' || echo "$content" | grep -q 'on AppFailure'; then
          clean=$((clean + 1))
        elif echo "$content" | grep -qE 'catch\s*\(\s*e\s*\)|catch\s*\(\s*_\s*\)'; then
          # A bare catch — might be catching generic Exception
          # Check if it's using AppFailure inside
          if echo "$content" | grep -q 'AppFailure'; then
            clean=$((clean + 1))
          else
            _check_err "$rel — uses generic Exception catch instead of AppFailure"
            err=$((err + 1))
          fi
        else
          clean=$((clean + 1))
        fi
      else
        clean=$((clean + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Cubit/Bloc convention ($clean/$total use AppFailure correctly)"
    fi
  }

  # ── Run all checks ─────────────────────────────────────────────────────────
  log_section "Architecture Audit"

  echo ""
  _check_1_feature_structure
  _check_2_sealed_states
  _check_3_banned_codegen
  _check_4_layer_boundaries
  _check_5_router_registration
  _check_6_di_registration
  _check_7_translation_keys
  _check_8_orphaned_generated
  _check_9_cubit_convention

  # ── Summary ────────────────────────────────────────────────────────────────
  echo ""
  if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    log_success "All checks passed — clean architecture!"
  elif [[ $errors -eq 0 ]]; then
    echo -e "  ${YELLOW}$warnings warning(s)${RESET} — see details above"
  else
    echo -e "  ${YELLOW}$warnings warning(s), ${RED}$errors error(s)${RESET} — see details above"
  fi
  echo ""

  # Exit codes: 0=all clear, 1=warnings only, 2=errors found
  if [[ $errors -gt 0 ]]; then
    exit 2
  elif [[ $warnings -gt 0 ]]; then
    exit 1
  fi
}

# ==============================================================================
#  COMMAND: doctor — Project Health
# ==============================================================================

cmd_doctor() {
  local issues=0

  # Helper: use the same prefix style as the rest of the CLI
  _doc_pass() { log_success "$1"; }
  _doc_warn() { issues=$((issues + 1)); log_warning "$1"; }
  _doc_info() { log_info "$1"; }

  log_section "Project Health"
  echo ""

  # ── Check 1: Flutter SDK ───────────────────────────────────────────────────
  if command -v flutter &>/dev/null; then
    local version_line
    version_line=$(flutter --version 2>/dev/null | head -1 || true)
    local version
    version=$(echo "$version_line" | sed -nE 's/.*Flutter ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')
    if [[ -n "$version" ]]; then
      _doc_pass "Flutter SDK $version"
    else
      _doc_pass "Flutter SDK detected (version unknown)"
    fi
  else
    _doc_warn "Flutter SDK not found in PATH — install flutter to use this CLI"
  fi

  # ── Check 2: Project root ──────────────────────────────────────────────────
  if [[ -f "pubspec.yaml" ]]; then
    local pkg_name
    pkg_name=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    if [[ -n "$pkg_name" ]]; then
      _doc_pass "Project root detected — $pkg_name"
    else
      _doc_warn "pubspec.yaml found but missing 'name:' field"
    fi
  else
    _doc_warn "pubspec.yaml not found — not a Flutter project root"
  fi

  # ── Check 3: Required packages ─────────────────────────────────────────────
  _check_required_packages() {
    if [[ ! -f "pubspec.yaml" ]]; then
      _doc_warn "Cannot check required packages — pubspec.yaml not found"
      return
    fi

    local required=(
      "flutter_bloc"
      "equatable"
      "get_it"
      "auto_route"
      "dio"
      "connectivity_plus"
      "flutter_secure_storage"
      "easy_localization"
      "logger"
      "intl"
      "pretty_dio_logger"
    )

    local dev_required=(
      "build_runner"
      "auto_route_generator"
    )

    local missing=0
    local found=0

    for pkg in "${required[@]}"; do
      if grep -qE "^[[:space:]]*${pkg}\b[[:space:]]*:" pubspec.yaml 2>/dev/null; then
        found=$((found + 1))
      else
        missing=$((missing + 1))
      fi
    done

    # Also check dev dependencies
    local dev_found=0
    local dev_missing=0
    for pkg in "${dev_required[@]}"; do
      if grep -qE "^[[:space:]]*${pkg}\b[[:space:]]*:" pubspec.yaml 2>/dev/null; then
        dev_found=$((dev_found + 1))
      else
        dev_missing=$((dev_missing + 1))
      fi
    done

    local total_runtime=${#required[@]}
    local total_dev=${#dev_required[@]}
    local total=$((total_runtime + total_dev))
    local total_found=$((found + dev_found))

    if [[ $missing -eq 0 && $dev_missing -eq 0 ]]; then
      _doc_pass "Required packages ($total_found/$total)"
    else
      local msg=""
      [[ $missing -gt 0 ]] && msg="$missing runtime package(s) missing"
      [[ $dev_missing -gt 0 ]] && msg="$msg, $dev_missing dev package(s) missing"
      _doc_warn "Required packages — $msg"
    fi
  }
  _check_required_packages

  # ── Check 4: Generated code ────────────────────────────────────────────────
  _check_generated_code() {
    local gr_count g_count
    gr_count=$(find lib/ -name '*.gr.dart' -print 2>/dev/null | wc -l) || true
    g_count=$(find lib/ -name '*.g.dart' -print 2>/dev/null | wc -l) || true
    : "${gr_count:=0}" "${g_count:=0}"
    local total_gen=$((gr_count + g_count))

    if [[ $total_gen -gt 0 ]]; then
      _doc_pass "Generated code found ($total_gen generated files)"
    else
      _doc_warn "Build runner not run — dart run build_runner build --delete-conflicting-outputs"
    fi
  }
  _check_generated_code

  # ── Check 5: Scaffold integrity ────────────────────────────────────────────
  _check_scaffold_integrity() {
    local required_dirs=(
      "lib/core/config"
      "lib/core/api/interceptors"
      "lib/core/auth"
      "lib/core/storage"
      "lib/core/error"
      "lib/core/bloc"
      "lib/core/theme"
      "lib/core/di"
      "lib/core/router"
      "lib/features"
      "lib/shared/models"
      "lib/shared/widgets"
      "lib/shared/utils"
      "assets/translations"
    )

    local required_files=(
      "lib/main.dart"
      "lib/main_dev.dart"
      "lib/main_staging.dart"
      "lib/main_prod.dart"
      "lib/app.dart"
      "lib/core/bootstrap.dart"
      "lib/core/config/app_config.dart"
      "lib/core/di/service_locator.dart"
      "lib/core/router/app_router.dart"
      "lib/core/api/api_client.dart"
      "lib/core/api/api_endpoints.dart"
      "lib/core/api/interceptors/auth_interceptor.dart"
      "lib/core/api/interceptors/retry_interceptor.dart"
      "lib/core/api/interceptors/connectivity_interceptor.dart"
      "lib/core/storage/secure_storage.dart"
      "lib/core/error/failures.dart"
      "lib/core/error/exception_mapper.dart"
      "lib/core/auth/auth_guard.dart"
      "lib/core/bloc/app_bloc_observer.dart"
      "lib/core/theme/app_theme.dart"
      "lib/core/custom_transition_builders.dart"
      "lib/shared/widgets/loading_shimmer.dart"
      "lib/shared/widgets/empty_state.dart"
      "lib/shared/widgets/error_state.dart"
    )

    local missing_dirs=0
    local missing_files=0

    for d in "${required_dirs[@]}"; do
      [[ -d "$d" ]] || missing_dirs=$((missing_dirs + 1))
    done

    for f in "${required_files[@]}"; do
      [[ -f "$f" ]] || missing_files=$((missing_files + 1))
    done

    if [[ $missing_dirs -eq 0 && $missing_files -eq 0 ]]; then
      _doc_pass "Scaffold structure intact (${#required_dirs[@]} dirs, ${#required_files[@]} files)"
    else
      _doc_warn "Scaffold structure — $missing_dirs missing dir(s), $missing_files missing file(s)"
    fi
  }
  _check_scaffold_integrity

  # ── Check 6: Outdated packages ─────────────────────────────────────────────
  _check_outdated_packages() {
    if ! command -v flutter &>/dev/null; then
      _doc_info "Skipping outdated packages check — flutter not in PATH"
      return
    fi

    if [[ ! -f "pubspec.yaml" ]]; then
      _doc_info "Skipping outdated packages check — no pubspec.yaml"
      return
    fi

    # Run flutter pub outdated and count upgradable packages
    local outdated_output
    outdated_output=$(flutter pub outdated 2>/dev/null) || true
    local upgradable
    upgradable=$(echo "$outdated_output" | grep -cE '\*\s+[0-9]' 2>/dev/null || echo 0)

    if [[ -n "$outdated_output" ]]; then
      if [[ "$upgradable" -gt 0 ]]; then
        _doc_info "$upgradable package(s) have updates available — run flutter pub outdated"
      else
        _doc_pass "All packages up to date"
      fi
    else
      _doc_info "Could not check outdated packages — flutter pub outdated failed"
    fi
  }
  _check_outdated_packages

  # ── Check 7: Git ───────────────────────────────────────────────────────────
  if [[ -d ".git" ]]; then
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local remote
    remote=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ -n "$remote" ]]; then
      _doc_pass "Git initialized — on branch $branch, remote configured"
    else
      _doc_info "Git initialized — on branch $branch, no remote configured"
    fi
  else
    _doc_info "Git not initialized — run git init to start tracking"
  fi

  # ── Summary ────────────────────────────────────────────────────────────────
  echo ""
  if [[ $issues -eq 0 ]]; then
    log_success "Project looks healthy!"
  else
    echo -e "  ${YELLOW}$issues issue(s) found${RESET} — see details above"
  fi
  echo ""
}

# ==============================================================================
#  COMMAND: generate — Individual component generators
# ==============================================================================

cmd_generate() {
  local type="${1:-}"
  local feature="${2:-}"
  local name="${3:-}"

  # If name not given, default to feature name
  if [[ -z "$name" ]]; then
    name="$feature"
  fi

  if [[ -z "$type" || -z "$feature" ]]; then
    log_error "Usage: flut generate <model|screen|repository|cubit|bloc> <feature> [name]"
    echo ""
    echo "  Examples:"
    echo "    flut generate model auth"
    echo "    flut generate model auth login_request"
    echo "    flut generate screen auth"
    echo "    flut generate repository auth"
    echo "    flut generate cubit auth"
    echo "    flut generate bloc auth"
    exit 1
  fi

  if [[ ! "$feature" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Feature name must be snake_case."
    exit 1
  fi

  if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Component name must be snake_case."
    exit 1
  fi

  local BASE="lib/features/$feature"
  if [[ ! -d "$BASE" ]]; then
    log_error "Feature '$feature' does not exist at $BASE"
    log_info "Create it first with: flut feature $feature"
    exit 1
  fi

  local pascal
  pascal=$(to_pascal "$name")
  local feature_pascal
  feature_pascal=$(to_pascal "$feature")

  # Detect package name from pubspec.yaml
  local pkg_name="your_app"
  if [[ -f "pubspec.yaml" ]]; then
    local parsed
    parsed=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    [[ -n "$parsed" ]] && pkg_name="$parsed"
  fi

  case "$type" in
    model)
      _gen_model
      ;;
    screen)
      _gen_screen
      ;;
    repository)
      _gen_repository
      ;;
    cubit)
      _gen_cubit
      ;;
    bloc)
      _gen_bloc
      ;;
    *)
      log_error "Unknown type: $type"
      echo "  Valid types: model, screen, repository, cubit, bloc"
      exit 1
      ;;
  esac
}

# ── Generate: model ────────────────────────────────────────────────────────────
_gen_model() {
  mkf "$BASE/data/models/${name}_model.dart" "class ${pascal}Model {
  const ${pascal}Model({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  ${pascal}Model copyWith({
    String? id,
    // TODO: add fields
  }) {
    return ${pascal}Model(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${pascal}Model && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '${pascal}Model(id: \$id)';
}
"
  echo ""
  log_section "Next steps for ${feature}.${name}_model"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     // ${pascal}Model used by ${feature_pascal}Repository"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     // Add API endpoint for ${name}s if needed"
  echo ""
}

# ── Generate: screen ───────────────────────────────────────────────────────────
_gen_screen() {
  mkf "$BASE/presentation/screens/${name}_screen.dart" "import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/${feature}_cubit.dart';
import '../../business_logic/${feature}_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<${feature_pascal}Cubit>()..load(),
      child: const _${pascal}View(),
    );
  }
}

class _${pascal}View extends StatelessWidget {
  const _${pascal}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${name}.title'.tr())),
      body: BlocConsumer<${feature_pascal}Cubit, ${feature_pascal}State>(
        listener: (context, state) {
          if (state is ${feature_pascal}Error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          ${feature_pascal}Initial() => const SizedBox.shrink(),
          ${feature_pascal}Loading() => const Center(child: LoadingShimmer()),
          ${feature_pascal}Error()   => ErrorState(
              message: (state as ${feature_pascal}Error).message,
              onRetry: () => context.read<${feature_pascal}Cubit>().load(),
            ),
          ${feature_pascal}Loaded()  => _${pascal}List(
              items: (state as ${feature_pascal}Loaded).items,
            ),
        },
      ),
    );
  }
}

class _${pascal}List extends StatelessWidget {
  const _${pascal}List({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: '${name}.empty'.tr());
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].id)),
      // TODO: build item UI
    );
  }
}
"
  echo ""
  log_section "Next steps for ${feature}.${name}_screen"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/router/app_router.dart${RESET}"
  echo "     AutoRoute(page: ${pascal}Route.page),"
  echo ""
  echo -e "  ${YELLOW}2. assets/translations/fr.json  &  en.json${RESET}"
  echo "     \"${name}\": { \"title\": \"...\", \"empty\": \"...\" }"
  echo ""
}

# ── Generate: repository ───────────────────────────────────────────────────────
_gen_repository() {
  mkf "$BASE/data/repositories/${name}_repository.dart" "import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/${name}_model.dart';

class ${pascal}Repository {
  const ${pascal}Repository(this._dio);
  final Dio _dio;

  Future<List<${pascal}Model>> get${pascal}List() async {
    try {
      final response = await _dio.get(ApiEndpoints.${name}s);
      return (response.data as List)
          .map((e) => ${pascal}Model.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
"
  echo ""
  log_section "Next steps for ${feature}.${name}_repository"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     static const ${name}s = '/${name}s';"
  echo ""
}

# ── Generate: cubit ────────────────────────────────────────────────────────────
_gen_cubit() {
  # Check if state file exists, create if not
  local state_file="$BASE/business_logic/${feature}_state.dart"
  if [[ ! -f "$state_file" ]]; then
    mkf "$state_file" "import '../data/models/${feature}_model.dart';

sealed class ${feature_pascal}State { const ${feature_pascal}State(); }

final class ${feature_pascal}Initial extends ${feature_pascal}State { const ${feature_pascal}Initial(); }
final class ${feature_pascal}Loading extends ${feature_pascal}State { const ${feature_pascal}Loading(); }
final class ${feature_pascal}Loaded  extends ${feature_pascal}State {
  const ${feature_pascal}Loaded(this.items);
  final List<${feature_pascal}Model> items;
}
final class ${feature_pascal}Error extends ${feature_pascal}State {
  const ${feature_pascal}Error(this.message);
  final String message;
}
"
  fi

  mkf "$BASE/business_logic/${name}_cubit.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${feature}_state.dart';

class ${pascal}Cubit extends Cubit<${feature_pascal}State> {
  ${pascal}Cubit(this._repository) : super(const ${feature_pascal}Initial());
  final ${pascal}Repository _repository;

  Future<void> load() async {
    emit(const ${feature_pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      if (!isClosed) emit(${feature_pascal}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(${feature_pascal}Error(f.userMessage));
    }
  }
}
"
  echo ""
  log_section "Next steps for ${feature}.${name}_cubit"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerFactory<${pascal}Cubit>(() => ${pascal}Cubit(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/router/app_router.dart${RESET}"
  echo "     Add a route that provides ${pascal}Cubit"
  echo ""
}

# ── Generate: bloc ─────────────────────────────────────────────────────────────
_gen_bloc() {
  # Check if state file exists, create if not
  local state_file="$BASE/business_logic/${feature}_state.dart"
  if [[ ! -f "$state_file" ]]; then
    mkf "$state_file" "import '../data/models/${feature}_model.dart';

sealed class ${feature_pascal}State { const ${feature_pascal}State(); }

final class ${feature_pascal}Initial extends ${feature_pascal}State { const ${feature_pascal}Initial(); }
final class ${feature_pascal}Loading extends ${feature_pascal}State { const ${feature_pascal}Loading(); }
final class ${feature_pascal}Loaded  extends ${feature_pascal}State {
  const ${feature_pascal}Loaded(this.items);
  final List<${feature_pascal}Model> items;
}
final class ${feature_pascal}Error extends ${feature_pascal}State {
  const ${feature_pascal}Error(this.message);
  final String message;
}
"
  fi

  mkf "$BASE/business_logic/${name}_event.dart" "sealed class ${pascal}Event { const ${pascal}Event(); }

final class ${pascal}Load    extends ${pascal}Event { const ${pascal}Load(); }
final class ${pascal}Refresh extends ${pascal}Event { const ${pascal}Refresh(); }
// TODO: add events
"

  mkf "$BASE/business_logic/${name}_bloc.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${name}_event.dart';
import '${feature}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${feature_pascal}State> {
  ${pascal}Bloc(this._repository) : super(const ${feature_pascal}Initial()) {
    on<${pascal}Load>(_onLoad);
    on<${pascal}Refresh>(_onRefresh);
  }

  final ${pascal}Repository _repository;

  Future<void> _onLoad(${pascal}Load event, Emitter<${feature_pascal}State> emit) async {
    emit(const ${feature_pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      emit(${feature_pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${feature_pascal}Error(f.userMessage));
    }
  }

  Future<void> _onRefresh(${pascal}Refresh event, Emitter<${feature_pascal}State> emit) async {
    try {
      final items = await _repository.get${pascal}List();
      emit(${feature_pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${feature_pascal}Error(f.userMessage));
    }
  }
}
"
  echo ""
  log_section "Next steps for ${feature}.${name}_bloc"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerFactory<${pascal}Bloc>(() => ${pascal}Bloc(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/router/app_router.dart${RESET}"
  echo "     Add a route that provides ${pascal}Bloc"
  echo ""
}

# ==============================================================================
#  ENTRYPOINT
# ==============================================================================
usage() {
  echo ""
  echo -e "${BOLD}flut${RESET} - Flutter scaffold CLI"
  echo ""
  echo -e "  ${CYAN}flut init${RESET}                                  Init full lib/ scaffold"
  echo -e "  ${CYAN}flut feature <n>${RESET}                        Add feature (Cubit)"
  echo -e "  ${CYAN}flut feature <n> --bloc${RESET}              Add feature (Bloc)"
  echo -e "  ${CYAN}flut feature <n> --service${RESET}           Add feature with Service layer"
  echo -e "  ${CYAN}flut feature <n> --bloc --service${RESET}    Bloc + Service layer"
  echo -e "  ${CYAN}flut generate${RESET}                              Generate individual components"
  echo -e "  ${CYAN}flut check${RESET}                                  Audit architecture conventions"
  echo -e "  ${CYAN}flut doctor${RESET}                                 Check project health"
  echo -e "  ${CYAN}flut upgrade${RESET}                               Upgrade flut-cli to latest version"
  echo ""
  echo "  Examples:"
  echo "    flut init"
  echo "    flut feature auth"
  echo "    flut feature payment --bloc"
  echo "    flut feature order --service"
  echo "    flut feature checkout --bloc --service"
  echo "    flut generate model auth"
  echo "    flut generate model auth login_request"
  echo "    flut generate screen auth"
  echo "    flut generate repository auth"
  echo "    flut generate cubit auth"
  echo "    flut generate bloc auth"
  echo "    flut check"
  echo "    flut doctor"
  echo "    flut upgrade"
  echo ""
}

case "${1:-}" in
  init)     cmd_init ;;
  feature)  shift; cmd_feature "$@" ;;
  generate) shift; cmd_generate "$@" ;;
  check)    cmd_check ;;
  doctor)   cmd_doctor ;;
  upgrade)  cmd_upgrade ;;
  -h|--help|"") usage ;;
  *) log_error "Unknown command: $1"; usage; exit 1 ;;
esac