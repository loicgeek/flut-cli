#!/usr/bin/env bats
# =============================================================================
#  Tests for flut upgrade command
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Help / Usage ─────────────────────────────────────────────────────────────

@test "flut --help mentions upgrade command" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"upgrade"* ]]
}

@test "flut upgrade without git repo prints error" {
  # Create a clone-like directory without .git
  local fake_install="$SANDBOX_DIR/.flut-cli"
  mkdir -p "$fake_install"
  cp "$FLUT_SCRIPT" "$fake_install/flut.sh"
  chmod +x "$fake_install/flut.sh"

  run bash "$fake_install/flut.sh" upgrade
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a git repository"* ]]
}

@test "flut upgrade with git repo tries to fetch" {
  # Init a git repo
  local fake_install="$SANDBOX_DIR/.flut-cli"
  mkdir -p "$fake_install"
  cp "$FLUT_SCRIPT" "$fake_install/flut.sh"
  chmod +x "$fake_install/flut.sh"

  git -C "$fake_install" init
  git -C "$fake_install" config user.email "test@test.com"
  git -C "$fake_install" config user.name "Test"
  git -C "$fake_install" add -A
  git -C "$fake_install" commit -m "initial" --allow-empty

  # No remote configured — will fail at fetch
  run bash "$fake_install/flut.sh" upgrade
  [ "$status" -eq 1 ]
  [[ "$output" == *"fetch failed"* ]] || [[ "$output" == *"git fetch"* ]]
}
