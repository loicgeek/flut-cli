#!/usr/bin/env bats
# =============================================================================
#  Tests for flut generate — individual component generators
# =============================================================================

load helpers

setup() {
  setup_sandbox
  # Create a feature to generate components into
  run bash "$FLUT_SCRIPT" feature test_feat
  [ "$status" -eq 0 ]
}

teardown() {
  teardown_sandbox
}

# ── Help / Usage ─────────────────────────────────────────────────────────────

@test "flut --help mentions generate command" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"generate"* ]]
}

@test "flut generate without arguments prints error" {
  run bash "$FLUT_SCRIPT" generate
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "flut generate with unknown type prints error" {
  run bash "$FLUT_SCRIPT" generate unknown test_feat
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown type"* ]]
}

@test "flut generate without feature prints error" {
  run bash "$FLUT_SCRIPT" generate model
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "flut generate with nonexistent feature prints error" {
  run bash "$FLUT_SCRIPT" generate model nowhere
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "flut generate with invalid name prints error" {
  run bash "$FLUT_SCRIPT" generate model test_feat BadName
  [ "$status" -eq 1 ]
  [[ "$output" == *"snake_case"* ]]
}

# ── Generate: model ──────────────────────────────────────────────────────────

@test "flut generate model creates model file" {
  run bash "$FLUT_SCRIPT" generate model test_feat
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/test_feat/data/models/test_feat_model.dart"
  # The original model from flut feature already exists
}

@test "flut generate model with custom name creates model file" {
  run bash "$FLUT_SCRIPT" generate model test_feat custom_item
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/test_feat/data/models/custom_item_model.dart"
  assert_file_contains "lib/features/test_feat/data/models/custom_item_model.dart" \
    "class CustomItemModel"
  assert_file_contains "lib/features/test_feat/data/models/custom_item_model.dart" \
    "factory CustomItemModel.fromJson"
  assert_file_contains "lib/features/test_feat/data/models/custom_item_model.dart" \
    "Map<String, dynamic> toJson()"
}

# ── Generate: screen ─────────────────────────────────────────────────────────

@test "flut generate screen creates screen file" {
  run bash "$FLUT_SCRIPT" generate screen test_feat custom_page
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/test_feat/presentation/screens/custom_page_screen.dart"
  assert_file_contains "lib/features/test_feat/presentation/screens/custom_page_screen.dart" \
    "class CustomPageScreen"
  assert_file_contains "lib/features/test_feat/presentation/screens/custom_page_screen.dart" \
    "@RoutePage()"
  assert_file_contains "lib/features/test_feat/presentation/screens/custom_page_screen.dart" \
    "BlocProvider"
}

# ── Generate: repository ─────────────────────────────────────────────────────

@test "flut generate repository creates repository file" {
  run bash "$FLUT_SCRIPT" generate repository test_feat custom_repo
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/test_feat/data/repositories/custom_repo_repository.dart"
  assert_file_contains "lib/features/test_feat/data/repositories/custom_repo_repository.dart" \
    "class CustomRepoRepository"
  assert_file_contains "lib/features/test_feat/data/repositories/custom_repo_repository.dart" \
    "mapDioExceptionToFailure"
}

# ── Generate: cubit ──────────────────────────────────────────────────────────

@test "flut generate cubit creates cubit file" {
  run bash "$FLUT_SCRIPT" generate cubit test_feat custom_logic
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/test_feat/business_logic/custom_logic_cubit.dart"
  assert_file_contains "lib/features/test_feat/business_logic/custom_logic_cubit.dart" \
    "class CustomLogicCubit"
  assert_file_contains "lib/features/test_feat/business_logic/custom_logic_cubit.dart" \
    "AppFailure"
}

# ── Generate: bloc ───────────────────────────────────────────────────────────

@test "flut generate bloc creates bloc and event files" {
  run bash "$FLUT_SCRIPT" generate bloc test_feat custom_flow
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/test_feat/business_logic/custom_flow_bloc.dart"
  assert_file_exists "lib/features/test_feat/business_logic/custom_flow_event.dart"
  assert_file_contains "lib/features/test_feat/business_logic/custom_flow_bloc.dart" \
    "class CustomFlowBloc"
  assert_file_contains "lib/features/test_feat/business_logic/custom_flow_event.dart" \
    "sealed class CustomFlowEvent"
}

# ── Generate prints next steps ───────────────────────────────────────────────

@test "flut generate model prints next steps" {
  run bash "$FLUT_SCRIPT" generate model test_feat extra
  [ "$status" -eq 0 ]
  [[ "$output" == *"Next steps"* ]]
  [[ "$output" == *"service_locator"* ]]
}

@test "flut generate screen prints next steps" {
  run bash "$FLUT_SCRIPT" generate screen test_feat extra
  [ "$status" -eq 0 ]
  [[ "$output" == *"Next steps"* ]]
  [[ "$output" == *"app_router"* ]]
}

# ── Generated code must reference only things that exist ─────────────────────

@test "generate cubit recreates the feature repository when it is missing" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  rm "$SANDBOX_DIR/lib/features/product/data/repositories/product_repository.dart"
  rm "$SANDBOX_DIR/lib/features/product/data/models/product_model.dart"

  run bash "$FLUT_SCRIPT" generate cubit product listing
  [ "$status" -eq 0 ]
  # the cubit imports the feature repository, so it must exist afterwards
  assert_file_exists "lib/features/product/data/repositories/product_repository.dart"
  assert_file_exists "lib/features/product/data/models/product_model.dart"
}

@test "generate bloc recreates the feature repository when it is missing" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  rm "$SANDBOX_DIR/lib/features/product/data/repositories/product_repository.dart"

  run bash "$FLUT_SCRIPT" generate bloc product actions
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/data/repositories/product_repository.dart"
}

@test "generate screen binds to the feature's bloc when it uses one" {
  bash "$FLUT_SCRIPT" feature order --bloc >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate screen order summary
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/order/presentation/screens/summary_screen.dart" "order_bloc.dart"
  assert_file_not_contains "lib/features/order/presentation/screens/summary_screen.dart" "order_cubit.dart"
}

@test "generate screen binds to the feature's cubit by default" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate screen product detail
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/presentation/screens/detail_screen.dart" "product_cubit.dart"
}

# ── api_endpoints registration ───────────────────────────────────────────────

@test "feature registers its endpoint in api_endpoints.dart" {
  mkdir -p "$SANDBOX_DIR/lib/core/api"
  printf 'abstract final class ApiEndpoints {\n  // Add endpoints by domain below\n}\n' \
    > "$SANDBOX_DIR/lib/core/api/api_endpoints.dart"

  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/core/api/api_endpoints.dart" "static const products = '/products';"
}

@test "endpoint registration is idempotent" {
  mkdir -p "$SANDBOX_DIR/lib/core/api"
  printf 'abstract final class ApiEndpoints {\n  // Add endpoints by domain below\n}\n' \
    > "$SANDBOX_DIR/lib/core/api/api_endpoints.dart"

  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  bash "$FLUT_SCRIPT" generate repository product product >/dev/null 2>&1
  run grep -c "static const products" "$SANDBOX_DIR/lib/core/api/api_endpoints.dart"
  [ "$output" -eq 1 ]
}

@test "feature works when api_endpoints.dart is absent" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/data/repositories/product_repository.dart"
}

@test "generate cubit reads the feature repository so state types line up" {
  bash "$FLUT_SCRIPT" feature auth >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate cubit auth listing
  [ "$status" -eq 0 ]
  # shares AuthState, so it must read AuthRepository, not ListingRepository
  assert_file_contains "lib/features/auth/business_logic/listing_cubit.dart" "AuthRepository"
  assert_file_not_contains "lib/features/auth/business_logic/listing_cubit.dart" "ListingRepository"
}

@test "generate bloc reads the feature repository so state types line up" {
  bash "$FLUT_SCRIPT" feature auth >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate bloc auth actions
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/auth/business_logic/actions_bloc.dart" "AuthRepository"
  assert_file_not_contains "lib/features/auth/business_logic/actions_bloc.dart" "ActionsRepository"
}

@test "generate repository creates the model it imports" {
  bash "$FLUT_SCRIPT" feature auth >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate repository auth stock
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/auth/data/models/stock_model.dart"
}
