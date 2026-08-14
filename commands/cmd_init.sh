# ==============================================================================
#  COMMAND: init
# ==============================================================================
cmd_init() {
  local architecture="$FLUT_DEFAULT_ARCH"
  local arch_explicit=false

  # Parse flags (command name already shifted by the dispatcher)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --architecture|-a)
        architecture="${2:-}"
        if [[ -z "$architecture" ]]; then
          log_error "Missing value for --architecture"
          usage
          exit 1
        fi
        arch_explicit=true
        shift 2 ;;
      --architecture=*)
        architecture="${1#*=}"
        arch_explicit=true
        shift ;;
      *) log_error "Unknown flag: $1"; usage; exit 1 ;;
    esac
  done

  log_section "Initializing Flutter scaffold"

  if [[ ! -f "pubspec.yaml" ]]; then
    log_error "pubspec.yaml not found. Run from project root."
    exit 1
  fi

  # Re-inits keep the project's existing architecture unless one was given
  if [[ "$arch_explicit" == false && -f "$FLUT_CONFIG_FILE" ]]; then
    architecture="$(_arch_current)"
  fi

  if ! _arch_exists "$architecture"; then
    log_error "Unknown architecture: $architecture"
    echo "  Installed: $(_arch_list)"
    exit 1
  fi

  local L="lib"

  log_section "Architecture"
  log_info "profile: $architecture"
  _arch_write "$architecture"

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

  # shellcheck disable=SC2016  # $PROJECT_DIR$ is an IntelliJ variable, not bash
  mkf ".idea/runConfigurations/Dev.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Dev" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
    <option name="additionalArgs" value="" />
    <method v="2" />
  </configuration>
</component>
'

  # shellcheck disable=SC2016
  mkf ".idea/runConfigurations/Dev_profile.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Dev (profile)" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
    <option name="additionalArgs" value="--profile" />
    <method v="2" />
  </configuration>
</component>
'

  # shellcheck disable=SC2016
  mkf ".idea/runConfigurations/Staging.xml" '<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="Staging" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_staging.dart" />
    <option name="additionalArgs" value="" />
    <method v="2" />
  </configuration>
</component>
'

  # shellcheck disable=SC2016
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
