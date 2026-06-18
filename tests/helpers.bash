# =============================================================================
#  Test helpers for flut-cli BATS tests
# =============================================================================

# Path to the flut.sh script (from project root)
FLUT_SCRIPT="${BATS_TEST_DIRNAME}/../flut.sh"

# ── Sandbox management ───────────────────────────────────────────────────────

# Create a temporary Flutter-like project for testing.
# Changes directory into the sandbox so flut.sh can find pubspec.yaml.
# Options:
#   --no-pubspec   Do not create a pubspec.yaml (for testing missing pubspec)
setup_sandbox() {
  local create_pubspec=true

  for arg in "$@"; do
    case "$arg" in
      --no-pubspec) create_pubspec=false ;;
    esac
  done

  export SANDBOX_DIR
  SANDBOX_DIR="$(mktemp -d)"

  if [[ "$create_pubspec" == true ]]; then
    cat > "$SANDBOX_DIR/pubspec.yaml" <<'EOF'
name: test_app
description: A test Flutter project
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.0.0

dependencies:
  flutter:
    sdk: flutter
EOF
  fi

  # cd into sandbox so flut.sh finds pubspec.yaml in the current directory
  cd "$SANDBOX_DIR"
}

teardown_sandbox() {
  if [[ -n "${SANDBOX_DIR:-}" && -d "$SANDBOX_DIR" ]]; then
    rm -rf "$SANDBOX_DIR"
  fi
}

# ── Assertions ───────────────────────────────────────────────────────────────

# Assert a file exists (relative to SANDBOX_DIR)
assert_file_exists() {
  local path="$1"
  if [[ ! -f "$SANDBOX_DIR/$path" ]]; then
    echo "Expected file to exist: $path"
    return 1
  fi
}

# Assert a directory exists (relative to SANDBOX_DIR)
assert_dir_exists() {
  local path="$1"
  if [[ ! -d "$SANDBOX_DIR/$path" ]]; then
    echo "Expected directory to exist: $path"
    return 1
  fi
}

# Assert a file does NOT exist (relative to SANDBOX_DIR)
assert_file_not_exists() {
  local path="$1"
  if [[ -f "$SANDBOX_DIR/$path" ]]; then
    echo "Expected file to NOT exist: $path"
    return 1
  fi
}

# Assert a directory does NOT exist (relative to SANDBOX_DIR)
assert_dir_not_exists() {
  local path="$1"
  if [[ -d "$SANDBOX_DIR/$path" ]]; then
    echo "Expected directory to NOT exist: $path"
    return 1
  fi
}

# Assert a file contains a specific string
assert_file_contains() {
  local path="$1" pattern="$2"
  if [[ ! -f "$SANDBOX_DIR/$path" ]]; then
    echo "File does not exist: $path"
    return 1
  fi
  if ! grep -qF "$pattern" "$SANDBOX_DIR/$path"; then
    echo "Expected file '$path' to contain: $pattern"
    echo "--- file content ---"
    cat "$SANDBOX_DIR/$path"
    echo "---"
    return 1
  fi
}

# Assert a file does NOT contain a specific string
assert_file_not_contains() {
  local path="$1" pattern="$2"
  if [[ ! -f "$SANDBOX_DIR/$path" ]]; then
    return 0  # file doesn't exist, so definitely doesn't contain it
  fi
  if grep -qF "$pattern" "$SANDBOX_DIR/$path"; then
    echo "Expected file '$path' to NOT contain: $pattern"
    echo "--- file content ---"
    cat "$SANDBOX_DIR/$path"
    echo "---"
    return 1
  fi
}

# ── Feature structure helpers ────────────────────────────────────────────────

# Assert a feature has the correct directory structure
assert_feature_structure() {
  local name="$1"
  local base="lib/features/$name"

  assert_dir_exists "$base"
  assert_dir_exists "$base/business_logic"
  assert_dir_exists "$base/data/models"
  assert_dir_exists "$base/data/repositories"
  assert_dir_exists "$base/presentation/router"
  assert_dir_exists "$base/presentation/screens"
  assert_dir_exists "$base/presentation/widgets"

  # State file exists
  assert_file_exists "$base/business_logic/${name}_state.dart"

  # Model file exists
  assert_file_exists "$base/data/models/${name}_model.dart"

  # Repository file exists
  assert_file_exists "$base/data/repositories/${name}_repository.dart"

  # Router module file exists
  assert_file_exists "$base/presentation/router/${name}_router_module.dart"

  # Screen file exists
  assert_file_exists "$base/presentation/screens/${name}_screen.dart"
}
