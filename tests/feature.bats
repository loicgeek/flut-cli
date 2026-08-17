#!/usr/bin/env bats
# =============================================================================
#  Tests for flut feature command
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Default feature (Cubit, no service) ─────────────────────────────────────

@test "flut feature auth creates expected directory structure" {
  run bash "$FLUT_SCRIPT" feature auth
  [ "$status" -eq 0 ]

  assert_feature_structure "auth"
  assert_dir_not_exists "lib/features/auth/data/services"
}

@test "flut feature auth creates Cubit (not Bloc) by default" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_exists "lib/features/auth/business_logic/auth_cubit.dart"
  assert_file_not_exists "lib/features/auth/business_logic/auth_bloc.dart"
  assert_file_not_exists "lib/features/auth/business_logic/auth_event.dart"
}

@test "flut feature auth generates sealed state class" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/business_logic/auth_state.dart" \
    "sealed class AuthState"
}

@test "flut feature auth generates state variants (Initial, Loading, Loaded, Error)" {
  run bash "$FLUT_SCRIPT" feature auth

  # Note: template has extra spacing for alignment — match substrings
  assert_file_contains "lib/features/auth/business_logic/auth_state.dart" \
    "final class AuthInitial"
  assert_file_contains "lib/features/auth/business_logic/auth_state.dart" \
    "final class AuthLoading"
  assert_file_contains "lib/features/auth/business_logic/auth_state.dart" \
    "final class AuthLoaded"
  assert_file_contains "lib/features/auth/business_logic/auth_state.dart" \
    "final class AuthError"
}

@test "flut feature auth generates model with fromJson/toJson/copyWith" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/data/models/auth_model.dart" \
    "factory AuthModel.fromJson"
  assert_file_contains "lib/features/auth/data/models/auth_model.dart" \
    "Map<String, dynamic> toJson()"
  assert_file_contains "lib/features/auth/data/models/auth_model.dart" \
    "AuthModel copyWith"
}

@test "flut feature auth generates repository with Dio error handling" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/data/repositories/auth_repository.dart" \
    "class AuthRepository"
  assert_file_contains "lib/features/auth/data/repositories/auth_repository.dart" \
    "mapDioExceptionToFailure"
}

@test "flut feature auth generates screen with BlocProvider/BlocConsumer" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/presentation/screens/auth_screen.dart" \
    "BlocProvider"
  assert_file_contains "lib/features/auth/presentation/screens/auth_screen.dart" \
    "BlocConsumer"
  assert_file_contains "lib/features/auth/presentation/screens/auth_screen.dart" \
    "@RoutePage()"
}

@test "flut feature auth generates router module with custom transition" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/presentation/router/auth_router_module.dart" \
    "AuthRouterModule"
  assert_file_contains "lib/features/auth/presentation/router/auth_router_module.dart" \
    "customTransitionBuilder"
}

# ── Bloc flag ────────────────────────────────────────────────────────────────

@test "flut feature auth --bloc creates Bloc instead of Cubit" {
  run bash "$FLUT_SCRIPT" feature auth --bloc

  assert_file_exists "lib/features/auth/business_logic/auth_bloc.dart"
  assert_file_exists "lib/features/auth/business_logic/auth_event.dart"
  assert_file_not_exists "lib/features/auth/business_logic/auth_cubit.dart"
}

@test "flut feature auth --bloc generates event class" {
  run bash "$FLUT_SCRIPT" feature auth --bloc

  assert_file_contains "lib/features/auth/business_logic/auth_event.dart" \
    "sealed class AuthEvent"
  # Note: template has varied spacing for alignment
  assert_file_contains "lib/features/auth/business_logic/auth_event.dart" \
    "final class AuthLoad"
  assert_file_contains "lib/features/auth/business_logic/auth_event.dart" \
    "final class AuthRefresh"
}

@test "flut feature auth --bloc generates Bloc class with on<Event> handlers" {
  run bash "$FLUT_SCRIPT" feature auth --bloc

  assert_file_contains "lib/features/auth/business_logic/auth_bloc.dart" \
    "class AuthBloc extends Bloc"
  assert_file_contains "lib/features/auth/business_logic/auth_bloc.dart" \
    "on<AuthLoad>"
  assert_file_contains "lib/features/auth/business_logic/auth_bloc.dart" \
    "on<AuthRefresh>"
}

# ── Service flag ─────────────────────────────────────────────────────────────

@test "flut feature auth --service creates service layer" {
  run bash "$FLUT_SCRIPT" feature auth --service

  assert_dir_exists "lib/features/auth/data/services"
  assert_file_exists "lib/features/auth/data/services/auth_service.dart"
  assert_file_contains "lib/features/auth/data/services/auth_service.dart" \
    "class AuthService"
}

@test "flut feature auth --service repository delegates to service" {
  run bash "$FLUT_SCRIPT" feature auth --service

  assert_file_contains "lib/features/auth/data/repositories/auth_repository.dart" \
    "AuthService _service"
  assert_file_contains "lib/features/auth/data/repositories/auth_repository.dart" \
    "_service.getAuthList"
}

@test "flut feature auth --service default behavior (no service) uses raw Dio" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/data/repositories/auth_repository.dart" \
    "final Dio _dio"
  assert_file_contains "lib/features/auth/data/repositories/auth_repository.dart" \
    "ApiEndpoints.auths"
  assert_dir_not_exists "lib/features/auth/data/services"
}

# ── Bloc + Service combined ─────────────────────────────────────────────────

@test "flut feature auth --bloc --service creates Bloc with service" {
  run bash "$FLUT_SCRIPT" feature auth --bloc --service

  assert_file_exists "lib/features/auth/business_logic/auth_bloc.dart"
  assert_file_exists "lib/features/auth/data/services/auth_service.dart"
  assert_file_not_exists "lib/features/auth/business_logic/auth_cubit.dart"
}

# ── Duplicate feature ────────────────────────────────────────────────────────

@test "flut feature auth twice exits with error" {
  run bash "$FLUT_SCRIPT" feature auth
  [ "$status" -eq 0 ]

  run bash "$FLUT_SCRIPT" feature auth
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists"* ]]
}

# ── Package name detection ───────────────────────────────────────────────────

@test "flut feature uses package name from pubspec.yaml in router module" {
  run bash "$FLUT_SCRIPT" feature auth

  assert_file_contains "lib/features/auth/presentation/router/auth_router_module.dart" \
    "package:test_app/"
}

# ── Router module must reference the file auto_route actually generates ──────

@test "feature router module imports the .gr.dart auto_route generates" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/presentation/router/product_router_module.dart" \
    "import 'product_router_module.gr.dart';"
  assert_file_not_contains "lib/features/product/presentation/router/product_router_module.dart" \
    "product_router_module.g.dart'"
}

@test "bloc feature re-exports its events so the screen compiles" {
  run bash "$FLUT_SCRIPT" feature order --bloc
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/order/business_logic/order_bloc.dart" "export 'order_event.dart';"
}
