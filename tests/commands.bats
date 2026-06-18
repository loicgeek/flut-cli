#!/usr/bin/env bats
# =============================================================================
#  Tests for flut-cli command parsing & error handling
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Help / Usage ─────────────────────────────────────────────────────────────

@test "flut --help prints usage and exits successfully" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Flutter scaffold CLI"* ]]
  [[ "$output" == *"flut init"* ]]
  [[ "$output" == *"flut feature"* ]]
  [[ "$output" == *"flut upgrade"* ]]
}

@test "flut without arguments prints usage and exits successfully" {
  run bash "$FLUT_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Flutter scaffold CLI"* ]]
}

@test "flut -h prints usage and exits successfully" {
  run bash "$FLUT_SCRIPT" -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Flutter scaffold CLI"* ]]
}

# ── Unknown command ──────────────────────────────────────────────────────────

@test "flut with unknown command exits with error" {
  run bash "$FLUT_SCRIPT" nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
}

@test "flut with garbage args exits with error" {
  run bash "$FLUT_SCRIPT" --what-is-this
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown command"* ]]
}

# ── Feature validation ───────────────────────────────────────────────────────

@test "flut feature without name exits with error" {
  run bash "$FLUT_SCRIPT" feature
  [ "$status" -eq 1 ]
  [[ "$output" == *"Feature name is required"* ]]
}

@test "flut feature with invalid name (PascalCase) exits with error" {
  run bash "$FLUT_SCRIPT" feature BadName
  [ "$status" -eq 1 ]
  [[ "$output" == *"snake_case"* ]]
}

@test "flut feature with invalid name (camelCase) exits with error" {
  run bash "$FLUT_SCRIPT" feature camelCase
  [ "$status" -eq 1 ]
  [[ "$output" == *"snake_case"* ]]
}

@test "flut feature with invalid name (starts with digit) exits with error" {
  run bash "$FLUT_SCRIPT" feature 1feature
  [ "$status" -eq 1 ]
  [[ "$output" == *"snake_case"* ]]
}

@test "flut feature with invalid name (has spaces) exits with error" {
  run bash "$FLUT_SCRIPT" feature "my feature"
  [ "$status" -eq 1 ]
  [[ "$output" == *"snake_case"* ]]
}

@test "flut feature with unknown flag exits with error" {
  run bash "$FLUT_SCRIPT" feature auth --unknown
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown flag"* ]]
}

@test "flut feature with valid snake_case name succeeds" {
  run bash "$FLUT_SCRIPT" feature auth
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checklist"* ]]
}

@test "flut feature with multi-word snake_case name succeeds" {
  run bash "$FLUT_SCRIPT" feature user_profile
  [ "$status" -eq 0 ]
  [[ "$output" == *"Checklist"* ]]
}

# ── Init validation ──────────────────────────────────────────────────────────

@test "flut init fails without pubspec.yaml" {
  setup_sandbox --no-pubspec
  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 1 ]
  [[ "$output" == *"pubspec.yaml not found"* ]]
}

@test "flut init without flutter prints packages hint (not hard error)" {
  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 0 ]
  [[ "$output" == *"Scaffold ready"* ]] || [[ "$output" == *"Run manually"* ]]
}
