#!/usr/bin/env bats
# =============================================================================
#  Tests for flut assets — asset analysis and cleanup command
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Local helpers ─────────────────────────────────────────────────────────────

# Create a minimal assets/ structure in the sandbox.
_setup_assets() {
  mkdir -p assets/images assets/icons assets/lottie assets/translations
  mkdir -p lib
}

# Create a Dart file that directly uses an asset (not a mere assignment).
# $1 = dart file path (relative to sandbox), $2 = asset path to reference
_dart_with_ref() {
  local dart_file="$1" asset_ref="$2"
  mkdir -p "$(dirname "$dart_file")"
  printf "Widget build() => Image.asset('%s');\n" "$asset_ref" > "$dart_file"
}

# Create an empty asset file.
# $1 = asset path (relative to sandbox)
_make_asset() {
  local asset="$1"
  mkdir -p "$(dirname "$asset")"
  echo "fake-asset-data" > "$asset"
}

# ── Help / Usage ──────────────────────────────────────────────────────────────

@test "flut --help mentions assets command" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"assets"* ]]
}

@test "flut assets without subcommand prints usage" {
  run bash "$FLUT_SCRIPT" assets
  [ "$status" -eq 0 ]
  [[ "$output" == *"check"* ]]
  [[ "$output" == *"stats"* ]]
  [[ "$output" == *"clean"* ]]
}

@test "flut assets unknown subcommand exits with error" {
  run bash "$FLUT_SCRIPT" assets bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown assets subcommand"* ]]
}

# ── Guard: missing assets/ directory ─────────────────────────────────────────

@test "flut assets check fails without assets/ directory" {
  run bash "$FLUT_SCRIPT" assets check
  [ "$status" -eq 1 ]
  [[ "$output" == *"No assets/"* ]]
}

# ── flut assets check ─────────────────────────────────────────────────────────

@test "flut assets check exits 0 when all assets are referenced" {
  _setup_assets
  _make_asset "assets/images/logo.png"
  _dart_with_ref "lib/home.dart" "assets/images/logo.png"

  run bash "$FLUT_SCRIPT" assets check
  [ "$status" -eq 0 ]
  [[ "$output" == *"All"* ]]
}

@test "flut assets check exits 1 and shows filename when asset is unused" {
  _setup_assets
  _make_asset "assets/images/unused.png"
  # lib/ exists but no dart file references the asset
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets check
  [ "$status" -eq 1 ]
  [[ "$output" == *"unused.png"* ]]
}

@test "flut assets check finds asset referenced by basename only" {
  _setup_assets
  _make_asset "assets/icons/close.svg"
  # Reference only the bare filename, not the full path
  _dart_with_ref "lib/widget.dart" "close.svg"

  run bash "$FLUT_SCRIPT" assets check
  [ "$status" -eq 0 ]
  [[ "$output" == *"All"* ]]
}

@test "flut assets check excludes translations directory" {
  _setup_assets
  # Put a file in translations that is NOT referenced in Dart
  echo '{"key": "value"}' > assets/translations/en.json
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets check
  # translations are excluded so the check should not flag en.json
  [ "$status" -eq 0 ]
}

@test "flut assets check summary shows correct unused count" {
  _setup_assets
  _make_asset "assets/images/a.png"
  _make_asset "assets/images/b.png"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets check
  [ "$status" -eq 1 ]
  [[ "$output" == *"2 unused"* ]]
}

# ── flut assets stats ─────────────────────────────────────────────────────────

@test "flut assets stats exits 0 on empty assets dir" {
  _setup_assets
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets stats
  [ "$status" -eq 0 ]
}

@test "flut assets stats shows images category when image assets present" {
  _setup_assets
  _make_asset "assets/images/photo.jpg"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"images"* ]]
}

@test "flut assets stats shows total count" {
  _setup_assets
  _make_asset "assets/images/img1.png"
  _make_asset "assets/icons/icon1.svg"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets stats
  [ "$status" -eq 0 ]
  [[ "$output" == *"Total"* ]]
}

# ── flut assets clean --dry-run ───────────────────────────────────────────────

@test "flut assets clean --dry-run exits 0 when no unused assets" {
  _setup_assets
  _make_asset "assets/images/used.png"
  _dart_with_ref "lib/screen.dart" "assets/images/used.png"

  run bash "$FLUT_SCRIPT" assets clean --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"No unused"* ]]
}

@test "flut assets clean --dry-run does not delete the file" {
  _setup_assets
  _make_asset "assets/images/ghost.png"
  touch lib/.gitkeep

  # Pipe 'y' so the dry-run confirmation path is exercised if needed
  run bash "$FLUT_SCRIPT" assets clean --dry-run <<< "y"
  [ "$status" -eq 0 ]
  [[ -f "assets/images/ghost.png" ]]
  [[ "$output" == *"dry run"* ]] || [[ "$output" == *"Dry run"* ]]
}

@test "flut assets clean unknown flag exits with error" {
  _setup_assets
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets clean --bogus
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown flag"* ]]
}

# ── flut assets clean (interactive, one by one) ───────────────────────────────

@test "flut assets clean with y deletes the file" {
  _setup_assets
  _make_asset "assets/images/delete_me.png"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets clean <<< "y"
  [ "$status" -eq 0 ]
  [[ ! -f "assets/images/delete_me.png" ]]
}

@test "flut assets clean with N keeps the file" {
  _setup_assets
  _make_asset "assets/images/keep_me.png"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets clean <<< "N"
  [ "$status" -eq 0 ]
  [[ -f "assets/images/keep_me.png" ]]
}

@test "flut assets clean with q stops early and keeps files" {
  _setup_assets
  _make_asset "assets/images/first.png"
  _make_asset "assets/images/second.png"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets clean <<< "q"
  [ "$status" -eq 0 ]
  # Both files should still be there (quit before deleting anything)
  [[ -f "assets/images/first.png" ]]
  [[ -f "assets/images/second.png" ]]
}

# ── flut assets clean --all ───────────────────────────────────────────────────

@test "flut assets clean --all with y deletes all unused assets" {
  _setup_assets
  _make_asset "assets/images/one.png"
  _make_asset "assets/icons/two.svg"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets clean --all <<< "y"
  [ "$status" -eq 0 ]
  [[ ! -f "assets/images/one.png" ]]
  [[ ! -f "assets/icons/two.svg" ]]
  [[ "$output" == *"deleted"* ]]
}

@test "flut assets clean --all with N aborts and keeps files" {
  _setup_assets
  _make_asset "assets/images/stay.png"
  touch lib/.gitkeep

  run bash "$FLUT_SCRIPT" assets clean --all <<< "N"
  [ "$status" -eq 0 ]
  [[ -f "assets/images/stay.png" ]]
  [[ "$output" == *"Aborted"* ]]
}
