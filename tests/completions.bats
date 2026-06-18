#!/usr/bin/env bats
# =============================================================================
#  Tests for flut shell completions (bash and zsh)
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

COMPLETIONS_DIR="${BATS_TEST_DIRNAME}/../completions"

# ── File existence ────────────────────────────────────────────────────────────

@test "completions/flut.bash exists" {
  [[ -f "$COMPLETIONS_DIR/flut.bash" ]]
}

@test "completions/flut.zsh exists" {
  [[ -f "$COMPLETIONS_DIR/flut.zsh" ]]
}

# ── Bash completion: sourcing ─────────────────────────────────────────────────

@test "flut.bash sources without errors" {
  run bash -c "source '$COMPLETIONS_DIR/flut.bash'"
  [ "$status" -eq 0 ]
}

@test "_flut_complete function is defined after sourcing flut.bash" {
  run bash -c "source '$COMPLETIONS_DIR/flut.bash'; declare -f _flut_complete"
  [ "$status" -eq 0 ]
  [[ "$output" == *"_flut_complete"* ]]
}

# ── Bash completion: top-level commands ──────────────────────────────────────

@test "bash completion suggests top-level commands" {
  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut '')
    COMP_CWORD=1
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"init"* ]]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"check"* ]]
  [[ "$output" == *"doctor"* ]]
  [[ "$output" == *"generate"* ]]
  [[ "$output" == *"upgrade"* ]]
}

@test "bash completion suggests --help at top level" {
  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut '--')
    COMP_CWORD=1
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"--help"* ]]
}

# ── Bash completion: feature flags ──────────────────────────────────────────

@test "bash completion suggests --bloc and --service for feature command" {
  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut feature '')
    COMP_CWORD=2
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"--bloc"* ]]
  [[ "$output" == *"--service"* ]]
}

# ── Bash completion: generate subcommand ──────────────────────────────────────

@test "bash completion suggests generate types" {
  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut generate '')
    COMP_CWORD=2
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"model"* ]]
  [[ "$output" == *"screen"* ]]
  [[ "$output" == *"repository"* ]]
  [[ "$output" == *"cubit"* ]]
  [[ "$output" == *"bloc"* ]]
}

@test "bash completion suggests --feature flag for generate subtype" {
  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut generate model '')
    COMP_CWORD=3
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"--feature"* ]]
}

# ── Bash completion: dynamic feature names ───────────────────────────────────

@test "bash completion suggests existing features after --feature" {
  # Create two feature directories
  mkdir -p "lib/features/auth"
  mkdir -p "lib/features/user_profile"

  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut generate model --feature '')
    COMP_CWORD=4
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"auth"* ]]
  [[ "$output" == *"user_profile"* ]]
}

@test "bash completion returns empty feature list when no features exist" {
  run bash -c "
    source '$COMPLETIONS_DIR/flut.bash'
    COMP_WORDS=(flut generate model --feature '')
    COMP_CWORD=4
    _flut_complete
    echo \"\${COMPREPLY[*]}\"
  "
  [ "$status" -eq 0 ]
  # No features exist — output should be empty or only whitespace
  [[ -z "${output// /}" ]]
}

# ── Zsh completion: sourcing ──────────────────────────────────────────────────

@test "flut.zsh sources without errors" {
  command -v zsh &>/dev/null || skip "zsh not available"
  run zsh -c "source '$COMPLETIONS_DIR/flut.zsh'"
  [ "$status" -eq 0 ]
}

@test "_flut function is defined after sourcing flut.zsh" {
  command -v zsh &>/dev/null || skip "zsh not available"
  run zsh -c "source '$COMPLETIONS_DIR/flut.zsh'; functions _flut"
  [ "$status" -eq 0 ]
  [[ "$output" == *"_flut"* ]]
}

# ── install.sh mentions completions ──────────────────────────────────────────

@test "install.sh mentions bash completion setup" {
  local install_sh="${BATS_TEST_DIRNAME}/../install.sh"
  grep -q "completions/flut.bash" "$install_sh"
}

@test "install.sh mentions zsh completion setup" {
  local install_sh="${BATS_TEST_DIRNAME}/../install.sh"
  grep -q "completions/flut.zsh" "$install_sh"
}
