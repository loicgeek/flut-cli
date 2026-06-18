#!/usr/bin/env bats
# =============================================================================
#  Tests for flut clean — remove generated files
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Help / Usage ─────────────────────────────────────────────────────────────

@test "flut --help mentions clean command" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}

# ── No generated files ────────────────────────────────────────────────────────

@test "flut clean on project with no generated files exits 0" {
  mkdir -p lib/core
  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"No generated files found"* ]]
}

@test "flut clean without lib/ directory exits with error" {
  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 1 ]
  [[ "$output" == *"lib/"* ]]
}

# ── Removes .gr.dart files ───────────────────────────────────────────────────

@test "flut clean removes .gr.dart files" {
  mkdir -p lib/core/router
  touch lib/core/router/app_router.gr.dart

  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ ! -f "lib/core/router/app_router.gr.dart" ]]
  [[ "$output" == *"app_router.gr.dart"* ]]
}

@test "flut clean removes .g.dart files" {
  mkdir -p lib/core/di
  touch lib/core/di/service_locator.g.dart

  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ ! -f "lib/core/di/service_locator.g.dart" ]]
  [[ "$output" == *"service_locator.g.dart"* ]]
}

@test "flut clean removes both .gr.dart and .g.dart files" {
  mkdir -p lib/core/router lib/core/di
  touch lib/core/router/app_router.gr.dart
  touch lib/core/di/service_locator.g.dart

  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ ! -f "lib/core/router/app_router.gr.dart" ]]
  [[ ! -f "lib/core/di/service_locator.g.dart" ]]
}

@test "flut clean reports correct count of removed files" {
  mkdir -p lib/core/router lib/features/auth/presentation/router
  touch lib/core/router/app_router.gr.dart
  touch lib/features/auth/presentation/router/auth_router.gr.dart

  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 generated file(s) removed"* ]]
}

@test "flut clean does not remove regular .dart files" {
  mkdir -p lib/core/router
  touch lib/core/router/app_router.dart
  touch lib/core/router/app_router.gr.dart

  run bash "$FLUT_SCRIPT" clean
  [ "$status" -eq 0 ]
  [[ -f "lib/core/router/app_router.dart" ]]
  [[ ! -f "lib/core/router/app_router.gr.dart" ]]
}

# ── build_runner hint ────────────────────────────────────────────────────────

@test "flut clean prints build_runner regeneration hint" {
  mkdir -p lib/core
  run bash "$FLUT_SCRIPT" clean
  [[ "$output" == *"build_runner"* ]]
}

# ── Unknown flag ──────────────────────────────────────────────────────────────

@test "flut clean with unknown flag exits with error" {
  mkdir -p lib/core
  run bash "$FLUT_SCRIPT" clean --unknown
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown flag"* ]]
}
