# ==============================================================================
#  COMMAND: doctor — Project Health
# ==============================================================================

cmd_doctor() {
  local issues=0

  # Helper: use the same prefix style as the rest of the CLI
  _doc_pass() { log_success "$1"; }
  _doc_warn() { issues=$((issues + 1)); log_warning "$1"; }
  _doc_info() { log_info "$1"; }

  _manifest_env

  log_section "Project Health"
  echo ""

  # ── Check 1: Flutter SDK ───────────────────────────────────────────────────
  if command -v flutter &>/dev/null; then
    local version_line
    version_line=$(flutter --version 2>/dev/null | head -1 || true)
    local version
    version=$(echo "$version_line" | sed -nE 's/.*Flutter ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p')
    if [[ -n "$version" ]]; then
      _doc_pass "Flutter SDK $version"
    else
      _doc_pass "Flutter SDK detected (version unknown)"
    fi
  else
    _doc_warn "Flutter SDK not found in PATH — install flutter to use this CLI"
  fi

  # ── Check 2: Project root ──────────────────────────────────────────────────
  if [[ -f "pubspec.yaml" ]]; then
    local pkg_name
    pkg_name=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    if [[ -n "$pkg_name" ]]; then
      _doc_pass "Project root detected — $pkg_name"
    else
      _doc_warn "pubspec.yaml found but missing 'name:' field"
    fi
  else
    _doc_warn "pubspec.yaml not found — not a Flutter project root"
  fi

  # ── Check 3: Required packages ─────────────────────────────────────────────
  _check_required_packages() {
    if [[ ! -f "pubspec.yaml" ]]; then
      _doc_warn "Cannot check required packages — pubspec.yaml not found"
      return
    fi

    local required=("${RUNTIME_PACKAGES[@]}")
    local dev_required=("${DEV_PACKAGES[@]}")

    local missing_count=0
    local found=0

    for pkg in "${required[@]}"; do
      if grep -qE "^[[:space:]]*${pkg}\b[[:space:]]*:" pubspec.yaml 2>/dev/null; then
        found=$((found + 1))
      else
        missing_count=$((missing_count + 1))
      fi
    done

    # Also check dev dependencies
    local dev_found=0
    local dev_missing=0
    for pkg in "${dev_required[@]}"; do
      if grep -qE "^[[:space:]]*${pkg}\b[[:space:]]*:" pubspec.yaml 2>/dev/null; then
        dev_found=$((dev_found + 1))
      else
        dev_missing=$((dev_missing + 1))
      fi
    done

    local total_runtime=${#required[@]}
    local total_dev=${#dev_required[@]}
    local total=$((total_runtime + total_dev))
    local total_found=$((found + dev_found))

    if [[ $missing_count -eq 0 && $dev_missing -eq 0 ]]; then
      _doc_pass "Required packages ($total_found/$total)"
    else
      local msg=""
      [[ $missing_count -gt 0 ]] && msg="$missing_count runtime package(s) missing"
      [[ $dev_missing -gt 0 ]] && msg="$msg, $dev_missing dev package(s) missing"
      _doc_warn "Required packages — $msg"
    fi
  }
  _check_required_packages

  # ── Check 4: Generated code ────────────────────────────────────────────────
  _check_generated_code() {
    local gr_count g_count
    gr_count=$(find lib/ -name '*.gr.dart' -print 2>/dev/null | wc -l) || true
    g_count=$(find lib/ -name '*.g.dart' -print 2>/dev/null | wc -l) || true
    : "${gr_count:=0}" "${g_count:=0}"
    local total_gen=$((gr_count + g_count))

    if [[ $total_gen -gt 0 ]]; then
      _doc_pass "Generated code found ($total_gen generated files)"
    else
      _doc_warn "Build runner not run — dart run build_runner build --delete-conflicting-outputs"
    fi
  }
  _check_generated_code

  # ── Check 5: Scaffold integrity ────────────────────────────────────────────
  _check_scaffold_integrity() {
    local required_dirs=("${REQUIRED_DIRS[@]}")
    local required_files=("${REQUIRED_FILES[@]}")

    local missing_dirs=0
    local missing_files=0

    for d in "${required_dirs[@]}"; do
      [[ -d "$d" ]] || missing_dirs=$((missing_dirs + 1))
    done

    for f in "${required_files[@]}"; do
      [[ -f "$f" ]] || missing_files=$((missing_files + 1))
    done

    if [[ $missing_dirs -eq 0 && $missing_files -eq 0 ]]; then
      _doc_pass "Scaffold structure intact (${#required_dirs[@]} dirs, ${#required_files[@]} files)"
    else
      _doc_warn "Scaffold structure — $missing_dirs missing dir(s), $missing_files missing file(s)"
    fi
  }
  _check_scaffold_integrity

  # ── Check 6: Outdated packages ─────────────────────────────────────────────
  _check_outdated_packages() {
    if ! command -v flutter &>/dev/null; then
      _doc_info "Skipping outdated packages check — flutter not in PATH"
      return
    fi

    if [[ ! -f "pubspec.yaml" ]]; then
      _doc_info "Skipping outdated packages check — no pubspec.yaml"
      return
    fi

    # Run flutter pub outdated and count upgradable packages
    local outdated_output
    outdated_output=$(flutter pub outdated 2>/dev/null) || true
    local upgradable
    upgradable=$(echo "$outdated_output" | grep -cE '\*\s+[0-9]' 2>/dev/null || echo 0)

    if [[ -n "$outdated_output" ]]; then
      if [[ "$upgradable" -gt 0 ]]; then
        _doc_info "$upgradable package(s) have updates available — run flutter pub outdated"
      else
        _doc_pass "All packages up to date"
      fi
    else
      _doc_info "Could not check outdated packages — flutter pub outdated failed"
    fi
  }
  _check_outdated_packages

  # ── Check 7: Git ───────────────────────────────────────────────────────────
  if [[ -d ".git" ]]; then
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    local remote
    remote=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ -n "$remote" ]]; then
      _doc_pass "Git initialized — on branch $branch, remote configured"
    else
      _doc_info "Git initialized — on branch $branch, no remote configured"
    fi
  else
    _doc_info "Git not initialized — run git init to start tracking"
  fi

  # ── Summary ────────────────────────────────────────────────────────────────
  echo ""
  if [[ $issues -eq 0 ]]; then
    log_success "Project looks healthy!"
  else
    echo -e "  ${YELLOW}$issues issue(s) found${RESET} — see details above"
  fi
  echo ""
}
