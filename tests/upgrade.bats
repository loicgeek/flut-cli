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

# A real install is a git clone, so the fake one must carry the whole CLI
# (flut.sh alone is only an entrypoint and cannot run any command).
make_fake_install() {
  local dest="$1"
  mkdir -p "$dest"
  cp "$FLUT_SCRIPT" "$dest/flut.sh"
  chmod +x "$dest/flut.sh"
  cp -r "${BATS_TEST_DIRNAME}/../commands" "$dest/commands"
  cp -r "${BATS_TEST_DIRNAME}/../architectures" "$dest/architectures"
  cp "${BATS_TEST_DIRNAME}/../VERSION" "$dest/VERSION" 2>/dev/null || true
}

@test "flut upgrade without git repo prints error" {
  # Create a clone-like directory without .git
  local fake_install="$SANDBOX_DIR/.flut-cli"
  make_fake_install "$fake_install"

  run bash "$fake_install/flut.sh" upgrade
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a git repository"* ]]
}

@test "flut upgrade with git repo tries to fetch" {
  # Init a git repo
  local fake_install="$SANDBOX_DIR/.flut-cli"
  make_fake_install "$fake_install"

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

# ── Partial install ──────────────────────────────────────────────────────────

@test "flut.sh without its commands/ directory reports a partial install" {
  local lone="$SANDBOX_DIR/.flut-lone"
  mkdir -p "$lone"
  cp "$FLUT_SCRIPT" "$lone/flut.sh"
  chmod +x "$lone/flut.sh"

  run bash "$lone/flut.sh" upgrade
  [ "$status" -eq 1 ]
  [[ "$output" == *"no command modules found"* ]]
  [[ "$output" != *"command not found"* ]]
}
