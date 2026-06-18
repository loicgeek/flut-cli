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
