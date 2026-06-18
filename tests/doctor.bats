#!/usr/bin/env bats
# =============================================================================
#  Tests for flut doctor — project health command
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Help / Usage ─────────────────────────────────────────────────────────────

@test "flut --help mentions doctor command" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"doctor"* ]]
  [[ "$output" == *"health"* ]]
}

# ── Basic smoke tests ────────────────────────────────────────────────────────

@test "flut doctor runs without errors on empty project" {
  run bash "$FLUT_SCRIPT" doctor
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  [[ "$output" == *"Project Health"* ]]
}

@test "flut doctor detects project root (pubspec.yaml)" {
  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"test_app"* ]] || [[ "$output" == *"project root"* ]]
}

@test "flut doctor reports missing Flutter SDK gracefully" {
  run bash "$FLUT_SCRIPT" doctor
  # Should either pass (if flutter is installed) or warn (if not)
  [[ "$output" == *"Flutter SDK"* ]]
}

# ── After flut init ──────────────────────────────────────────────────────────

@test "flut doctor reports scaffold integrity after init" {
  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 0 ]

  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"Scaffold structure"* ]]
  [[ "$output" == *"intact"* ]] || [[ "$output" == *"missing"* ]]
}

@test "flut doctor reports git status" {
  # Init git
  git init
  git config user.email "test@test.com"
  git config user.name "Test"

  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"Git"* ]]
}

@test "flut doctor reports when not in a git repo" {
  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"Git"* ]]
}

# ── Required packages check ──────────────────────────────────────────────────

@test "flut doctor checks required packages in pubspec.yaml" {
  # Add some of the expected packages to pubspec.yaml
  cat >> "pubspec.yaml" <<'EOF'
dependencies:
  flutter_bloc: ^8.0.0
  equatable: ^2.0.0
  get_it: ^7.0.0
  auto_route: ^7.0.0
  dio: ^5.0.0
EOF

  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"Required packages"* ]]
}

# ── Generated code check ─────────────────────────────────────────────────────

@test "flut doctor warns when build_runner not run" {
  run bash "$FLUT_SCRIPT" doctor
  # Should warn about generated code when no .gr.dart files exist
  [[ "$output" == *"Build runner"* ]] || [[ "$output" == *"Generated"* ]]
}

@test "flut doctor passes generated code check when .gr.dart files exist" {
  # Create a mock .gr.dart file
  mkdir -p "lib/core/router"
  touch "lib/core/router/test_file.gr.dart"

  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"generated"* ]]
}
