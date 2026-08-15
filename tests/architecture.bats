#!/usr/bin/env bats
# =============================================================================
#  Tests for flut architecture command & flut.json config
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Listing ───────────────────────────────────────────────────────────────────

@test "flut architecture lists installed architectures" {
  run bash "$FLUT_SCRIPT" architecture
  [ "$status" -eq 0 ]
  [[ "$output" == *"ntech"* ]]
}

@test "flut architecture marks ntech as current by default" {
  run bash "$FLUT_SCRIPT" architecture
  [ "$status" -eq 0 ]
  [[ "$output" == *"current"* ]]
  [[ "$output" == *"* ntech"* ]]
}

@test "flut architecture list subcommand works" {
  run bash "$FLUT_SCRIPT" architecture list
  [ "$status" -eq 0 ]
  [[ "$output" == *"ntech"* ]]
}

@test "flut architecture with unknown argument exits with error" {
  run bash "$FLUT_SCRIPT" architecture bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown argument"* ]]
}

# ── flut init --architecture ──────────────────────────────────────────────────

@test "flut init --architecture ntech writes flut.json" {
  run bash "$FLUT_SCRIPT" init --architecture ntech
  [ "$status" -eq 0 ]
  assert_file_exists "flut.json"
  assert_file_contains "flut.json" '"architecture"'
  assert_file_contains "flut.json" '"ntech"'
}

@test "flut init -a ntech writes flut.json (short flag)" {
  run bash "$FLUT_SCRIPT" init -a ntech
  [ "$status" -eq 0 ]
  assert_file_exists "flut.json"
  assert_file_contains "flut.json" '"ntech"'
}

@test "flut init --architecture=ntech writes flut.json (equals form)" {
  run bash "$FLUT_SCRIPT" init --architecture=ntech
  [ "$status" -eq 0 ]
  assert_file_exists "flut.json"
  assert_file_contains "flut.json" '"ntech"'
}

@test "flut init (default) writes ntech architecture" {
  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 0 ]
  assert_file_exists "flut.json"
  assert_file_contains "flut.json" '"ntech"'
}

@test "flut init with unknown architecture exits with error" {
  run bash "$FLUT_SCRIPT" init --architecture bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown architecture"* ]]
  assert_file_not_exists "flut.json"
}

@test "flut init --architecture without value exits with error" {
  run bash "$FLUT_SCRIPT" init --architecture
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing value"* ]]
}

@test "flut init with unknown flag still errors" {
  run bash "$FLUT_SCRIPT" init --bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown flag"* ]]
}

# ── flut architecture --set ───────────────────────────────────────────────────

@test "flut architecture --set writes flut.json" {
  run bash "$FLUT_SCRIPT" architecture --set ntech
  [ "$status" -eq 0 ]
  assert_file_exists "flut.json"
  assert_file_contains "flut.json" '"ntech"'
}

@test "flut architecture --set reflects in subsequent listing" {
  run bash "$FLUT_SCRIPT" architecture --set ntech
  [ "$status" -eq 0 ]
  run bash "$FLUT_SCRIPT" architecture
  [ "$status" -eq 0 ]
  [[ "$output" == *"current"* ]]
  [[ "$output" == *"* ntech"* ]]
}

@test "flut architecture --set with unknown architecture exits with error" {
  run bash "$FLUT_SCRIPT" architecture --set bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown architecture"* ]]
  assert_file_not_exists "flut.json"
}

@test "flut architecture --set without value exits with error" {
  run bash "$FLUT_SCRIPT" architecture --set
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage: flut architecture --set"* ]]
}

# ── Init flag validation ──────────────────────────────────────────────────────

@test "flut init --architecture ntech is idempotent" {
  run bash "$FLUT_SCRIPT" init --architecture ntech
  [ "$status" -eq 0 ]
  run bash "$FLUT_SCRIPT" init --architecture ntech
  [ "$status" -eq 0 ]
  assert_file_contains "flut.json" '"ntech"'
}
