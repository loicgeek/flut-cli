# ==============================================================================
#  COMMAND: upgrade
# ==============================================================================

cmd_upgrade() {
  local INSTALL_DIR="$_FLUT_SCRIPT_DIR"

  log_section "Upgrading flut-cli"
  log_info "Install dir: $INSTALL_DIR"

  # Read current version before the update
  local current_version
  current_version="$(tr -d '[:space:]' < "$INSTALL_DIR/VERSION" 2>/dev/null || true)"
  current_version="${current_version:-unknown}"
  log_info "Current version: v${current_version}"

  # ── Check GitHub releases for the latest published version ────────────────
  if command -v curl &>/dev/null; then
    local latest_release
    latest_release=$(curl -sf --max-time 5 \
      "https://api.github.com/repos/loicgeek/flut-cli/releases/latest" \
      2>/dev/null \
      | grep '"tag_name"' \
      | sed 's/.*"tag_name":[[:space:]]*"v\?\([^"]*\)".*/\1/' \
      | tr -d '[:space:]' \
      || true)
    if [[ -n "$latest_release" ]]; then
      if [[ "$latest_release" == "$current_version" ]]; then
        log_info "Latest release:  v${latest_release} (you are on the latest)"
      else
        log_info "Latest release:  v${latest_release} — upgrade available"
      fi
    fi
  fi

  if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    log_error "Cannot upgrade: $INSTALL_DIR is not a git repository."
    log_error "Re-install with: curl -fsSL https://raw.githubusercontent.com/loicgeek/flut-cli/main/install.sh | bash"
    exit 1
  fi

  # Detect the default remote branch (main or master)
  local remote_branch
  remote_branch=$(git -C "$INSTALL_DIR" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's|refs/remotes/origin/||') || remote_branch="main"

  local before
  before=$(git -C "$INSTALL_DIR" rev-parse --short HEAD)

  # Warn if local changes exist (they will be discarded)
  local dirty
  dirty=$(git -C "$INSTALL_DIR" status --porcelain 2>/dev/null)
  if [[ -n "$dirty" ]]; then
    log_warning "Local changes in $INSTALL_DIR will be discarded:"
    git -C "$INSTALL_DIR" status --short
    echo ""
  fi

  log_info "Fetching from origin..."
  git -C "$INSTALL_DIR" fetch origin "$remote_branch" || {
    log_error "git fetch failed. Check your connection."
    exit 1
  }

  log_info "Resetting to origin/$remote_branch..."
  git -C "$INSTALL_DIR" reset --hard "origin/$remote_branch"

  # Restore executable permission lost by git reset --hard when the file mode
  # in the index is 100644 (non-executable).
  chmod +x "$INSTALL_DIR/flut.sh"

  local after
  after=$(git -C "$INSTALL_DIR" rev-parse --short HEAD)

  local new_version
  new_version="$(tr -d '[:space:]' < "$INSTALL_DIR/VERSION" 2>/dev/null || true)"
  new_version="${new_version:-unknown}"

  echo ""
  if [[ "$before" == "$after" ]]; then
    log_success "Already up to date — v${new_version} (${after})."
  else
    log_success "Upgraded v${current_version} → v${new_version}  (${before} → ${after})"
    echo ""
    log_info "Changelog:"
    git -C "$INSTALL_DIR" log --oneline "${before}..${after}"
  fi
  echo ""
}
