#!/usr/bin/env bats
# =============================================================================
#  Tests for flut init command
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Core directory structure ─────────────────────────────────────────────────

@test "flut init creates core directories" {
  run bash "$FLUT_SCRIPT" init

  assert_dir_exists "lib/core/config"
  assert_dir_exists "lib/core/api/interceptors"
  assert_dir_exists "lib/core/auth"
  assert_dir_exists "lib/core/storage"
  assert_dir_exists "lib/core/error"
  assert_dir_exists "lib/core/bloc"
  assert_dir_exists "lib/core/theme"
  assert_dir_exists "lib/core/di"
  assert_dir_exists "lib/core/router"
  assert_dir_exists "lib/features"
  assert_dir_exists "lib/shared/models"
  assert_dir_exists "lib/shared/widgets"
  assert_dir_exists "lib/shared/utils"
}

@test "flut init creates asset directories" {
  run bash "$FLUT_SCRIPT" init

  assert_dir_exists "assets/translations"
  assert_dir_exists "assets/images"
  assert_dir_exists "assets/icons"
  assert_dir_exists "assets/lottie"
}

# ── Entry point files ────────────────────────────────────────────────────────

@test "flut init creates main entry point files" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists "lib/main.dart"
  assert_file_exists "lib/main_dev.dart"
  assert_file_exists "lib/main_staging.dart"
  assert_file_exists "lib/main_prod.dart"
}

@test "flut init main.dart bootstrap uses AppConfig.dev" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/main.dart" "AppConfig.dev"
}

@test "flut init main_dev.dart uses AppConfig.dev" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/main_dev.dart" "AppConfig.dev"
  assert_file_not_contains "lib/main_dev.dart" "AppConfig.staging"
  assert_file_not_contains "lib/main_dev.dart" "AppConfig.prod"
}

@test "flut init main_staging.dart uses AppConfig.staging" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/main_staging.dart" "AppConfig.staging"
}

@test "flut init main_prod.dart uses AppConfig.prod" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/main_prod.dart" "AppConfig.prod"
}

# ── Core files ───────────────────────────────────────────────────────────────

@test "flut init creates app.dart" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists "lib/app.dart"
  assert_file_contains "lib/app.dart" "MaterialApp.router"
  assert_file_contains "lib/app.dart" "AppTheme"
  assert_file_contains "lib/app.dart" "AppRouter"
}

@test "flut init creates config" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/config/app_config.dart" "enum AppFlavor"
  assert_file_contains "lib/core/config/app_config.dart" "static const dev = AppConfig"
  assert_file_contains "lib/core/config/app_config.dart" "AppFlavor.dev"
  assert_file_contains "lib/core/config/app_config.dart" "static const staging = AppConfig"
  assert_file_contains "lib/core/config/app_config.dart" "static const prod = AppConfig"
}

@test "flut init creates bootstrap.dart" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/bootstrap.dart" "WidgetsFlutterBinding.ensureInitialized"
  assert_file_contains "lib/core/bootstrap.dart" "EasyLocalization.ensureInitialized"
  assert_file_contains "lib/core/bootstrap.dart" "setupServiceLocator"
  assert_file_contains "lib/core/bootstrap.dart" "AppBlocObserver"
}

@test "flut init creates service_locator.dart" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/di/service_locator.dart" "final sl = GetIt.instance"
  assert_file_contains "lib/core/di/service_locator.dart" "setupServiceLocator"
  assert_file_contains "lib/core/di/service_locator.dart" "AppRouter"
  assert_file_contains "lib/core/di/service_locator.dart" "AuthInterceptor"
  assert_file_contains "lib/core/di/service_locator.dart" "RetryInterceptor"
  assert_file_contains "lib/core/di/service_locator.dart" "ConnectivityInterceptor"
}

@test "flut init creates app_router.dart" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/router/app_router.dart" "class AppRouter"
  assert_file_contains "lib/core/router/app_router.dart" "RootStackRouter"
  assert_file_contains "lib/core/router/app_router.dart" "AutoRouterConfig"
}

@test "flut init creates api_client.dart" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/api/api_client.dart" "buildDioClient"
  assert_file_contains "lib/core/api/api_client.dart" "PrettyDioLogger"
  assert_file_contains "lib/core/api/api_client.dart" "connectTimeout"
}

@test "flut init creates api_endpoints.dart" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/api/api_endpoints.dart" "abstract final class ApiEndpoints"
  assert_file_contains "lib/core/api/api_endpoints.dart" "login"
  assert_file_contains "lib/core/api/api_endpoints.dart" "refresh"
  assert_file_contains "lib/core/api/api_endpoints.dart" "logout"
}

@test "flut init creates all interceptors" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists "lib/core/api/interceptors/auth_interceptor.dart"
  assert_file_exists "lib/core/api/interceptors/retry_interceptor.dart"
  assert_file_exists "lib/core/api/interceptors/connectivity_interceptor.dart"

  assert_file_contains "lib/core/api/interceptors/auth_interceptor.dart" "class AuthInterceptor"
  assert_file_contains "lib/core/api/interceptors/retry_interceptor.dart" "class RetryInterceptor"
  assert_file_contains "lib/core/api/interceptors/retry_interceptor.dart" "maxRetries = 3"
  assert_file_contains "lib/core/api/interceptors/connectivity_interceptor.dart" "class ConnectivityInterceptor"
}

@test "flut init creates error handling files" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/error/failures.dart" "class AppFailure"
  assert_file_contains "lib/core/error/failures.dart" "AppFailure.noInternet"
  assert_file_contains "lib/core/error/failures.dart" "AppFailure.timeout"
  assert_file_contains "lib/core/error/failures.dart" "AppFailure.unauthorized"
  assert_file_contains "lib/core/error/failures.dart" "AppFailure.serverError"

  assert_file_contains "lib/core/error/exception_mapper.dart" "mapDioExceptionToFailure"
  assert_file_contains "lib/core/error/exception_mapper.dart" "DioExceptionType.badResponse"
}

@test "flut init creates auth guard" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/auth/auth_guard.dart" "class AuthGuard extends AutoRouteGuard"
}

@test "flut init creates storage" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/storage/secure_storage.dart" "class SecureStorage"
  assert_file_contains "lib/core/storage/secure_storage.dart" "saveTokens"
}

@test "flut init creates bloc observer" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/bloc/app_bloc_observer.dart" "class AppBlocObserver"
}

@test "flut init creates theme" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/theme/app_theme.dart" "abstract final class AppTheme"
  assert_file_contains "lib/core/theme/app_theme.dart" "static ThemeData light()"
  assert_file_contains "lib/core/theme/app_theme.dart" "static ThemeData dark()"
  assert_file_contains "lib/core/theme/app_theme.dart" "useMaterial3"
}

@test "flut init creates custom transition builders" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "lib/core/custom_transition_builders.dart" "customTransitionBuilder"
  assert_file_contains "lib/core/custom_transition_builders.dart" "FadeTransition"
}

# ── Shared widgets ───────────────────────────────────────────────────────────

@test "flut init creates shared widgets" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists "lib/shared/widgets/loading_shimmer.dart"
  assert_file_exists "lib/shared/widgets/empty_state.dart"
  assert_file_exists "lib/shared/widgets/error_state.dart"

  assert_file_contains "lib/shared/widgets/loading_shimmer.dart" "class LoadingShimmer"
  assert_file_contains "lib/shared/widgets/empty_state.dart" "class EmptyState"
  assert_file_contains "lib/shared/widgets/error_state.dart" "class ErrorState"
}

# ── Translations ─────────────────────────────────────────────────────────────

@test "flut init creates translation files" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists "assets/translations/fr.json"
  assert_file_exists "assets/translations/en.json"

  assert_file_contains "assets/translations/fr.json" '"Reessayer"'
  assert_file_contains "assets/translations/en.json" '"Retry"'
}

@test "flut init creates French translation with expected keys" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "assets/translations/fr.json" '"Chargement..."'
  assert_file_contains "assets/translations/fr.json" '"Annuler"'
  assert_file_contains "assets/translations/fr.json" '"Enregistrer"'
  assert_file_contains "assets/translations/fr.json" '"Fermer"'
}

@test "flut init creates English translation with expected keys" {
  run bash "$FLUT_SCRIPT" init

  assert_file_contains "assets/translations/en.json" '"Loading..."'
  assert_file_contains "assets/translations/en.json" '"Cancel"'
  assert_file_contains "assets/translations/en.json" '"Save"'
  assert_file_contains "assets/translations/en.json" '"Close"'
}

# ── IDE settings ─────────────────────────────────────────────────────────────

@test "flut init creates VS Code launch configurations" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists ".vscode/launch.json"
  assert_file_contains ".vscode/launch.json" '"Dev"'
  assert_file_contains ".vscode/launch.json" '"Staging"'
  assert_file_contains ".vscode/launch.json" '"Prod"'
  assert_file_contains ".vscode/launch.json" '"Dev (profile)"'
}

@test "flut init creates IntelliJ run configurations" {
  run bash "$FLUT_SCRIPT" init

  assert_file_exists ".idea/runConfigurations/Dev.xml"
  assert_file_exists ".idea/runConfigurations/Dev_profile.xml"
  assert_file_exists ".idea/runConfigurations/Staging.xml"
  assert_file_exists ".idea/runConfigurations/Prod.xml"
}

# ── Idempotency ──────────────────────────────────────────────────────────────

@test "flut init is idempotent (running twice doesn't crash)" {
  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 0 ]

  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 0 ]
  # Should not error — existing files print "exists - skipped" warnings
}

# ── Success output ───────────────────────────────────────────────────────────

@test "flut init prints 'Scaffold ready' at end" {
  run bash "$FLUT_SCRIPT" init

  [[ "$output" == *"Scaffold ready"* ]] || [[ "$output" == *"Next steps"* ]]
}
