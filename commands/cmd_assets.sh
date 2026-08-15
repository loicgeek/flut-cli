#!/usr/bin/env bash
# ==============================================================================
# cmd_assets.sh — Flutter Assets Analyzer (Bash 3.2 / macOS safe)
# ==============================================================================

# SC2126: `grep | wc -l` is deliberate - `grep -c` exits 1 on zero matches,
#         which would trip `set -e` in these counters.
# SC2059: the printf formats embed colour variables, which is intentional here.
# shellcheck disable=SC2126,SC2059

# ── Colors ─────────────────────────────────────────────────────────────────────
_A_RESET="\033[0m"
_A_RED="\033[31m"
_A_YELLOW="\033[33m"
_A_GREEN="\033[32m"
_A_CYAN="\033[36m"
_A_BOLD="\033[1m"
_A_DIM="\033[2m"

# ── Log helpers (fallback only — flut.sh canonical versions take precedence) ───
if ! declare -f log_info >/dev/null 2>&1; then
  log_info()    { echo -e "${_A_CYAN}  ->  ${_A_RESET}$1"; }
  log_error()   { echo -e "${_A_RED}  xx  ${_A_RESET}$1"; }
  log_success() { echo -e "${_A_GREEN}  ok  ${_A_RESET}$1"; }
  log_warning() { echo -e "${_A_YELLOW}  !!  ${_A_RESET}$1"; }
  log_section() { echo -e "\n${_A_BOLD}${_A_CYAN}>> $1${_A_RESET}"; }
fi

# ── Cache state ────────────────────────────────────────────────────────────────
_ASSET_CACHE_DIR=""
_ASSETS_USED_INDEX=""
_ASSETS_PUBSPEC_INDEX=""

# ── Init ───────────────────────────────────────────────────────────────────────
_assets_init() {
  _ASSET_CACHE_DIR="$(mktemp -d)"
  trap 'rm -rf "$_ASSET_CACHE_DIR"' EXIT

  _ASSETS_USED_INDEX="$_ASSET_CACHE_DIR/used.txt"
  _ASSETS_PUBSPEC_INDEX="$_ASSET_CACHE_DIR/pubspec.txt"

  : > "$_ASSETS_USED_INDEX"
  : > "$_ASSETS_PUBSPEC_INDEX"
}

# ── Asset file listing ─────────────────────────────────────────────────────────
_assets_list_files() {
  find assets/ \
    -type f \
    -not -path "assets/translations/*" \
    -not -name ".*" \
    2>/dev/null
}

# ── Category detection (icons check must come before extension patterns) ───────
_assets_category() {
  case "$1" in
    assets/icons/*)                        echo "icons"  ;;
    *.png|*.jpg|*.jpeg|*.webp|*.svg|*.gif) echo "images" ;;
    *.ttf|*.otf|*.woff|*.woff2)            echo "fonts"  ;;
    *.json|*.riv|*.lottie)                 echo "lottie" ;;
    *)                                     echo "other"  ;;
  esac
}

# ── Size helpers ───────────────────────────────────────────────────────────────
_assets_size() { stat -f%z "$1" 2>/dev/null || echo 0; }

_assets_fmt_size() {
  local b="$1"
  awk -v b="$b" 'BEGIN {
    if      (b < 1024)    printf "%d B",    b
    else if (b < 1048576) printf "%.1f KB", b/1024
    else                  printf "%.1f MB", b/1048576
  }'
}

_assets_color_size() {
  local b="$1"
  local s; s="$(_assets_fmt_size "$b")"
  if   (( b > 1048576 )); then echo -e "${_A_RED}${s}${_A_RESET}"
  elif (( b > 200000  )); then echo -e "${_A_YELLOW}${s}${_A_RESET}"
  else                         echo -e "${_A_GREEN}${s}${_A_RESET}"
  fi
}

# ── Pubspec index ──────────────────────────────────────────────────────────────
_assets_index_pubspec() {
  awk '
    $1 == "assets:" { flag=1; next }
    flag && /^[a-zA-Z]/ { flag=0 }
    flag && /- / { print "assets/" $2 }
  ' pubspec.yaml 2>/dev/null > "$_ASSETS_PUBSPEC_INDEX"
}

# ── Dart AST index ─────────────────────────────────────────────────────────────
_assets_index_dart() {
  local FLUT_HOME="${FLUT_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  dart "$FLUT_HOME/engine/asset_analyzer.dart" < /dev/null > "$_ASSETS_USED_INDEX"
}

# ── Build indexes ──────────────────────────────────────────────────────────────
_assets_build() {
  _assets_init
  log_info "Scanning pubspec..."
  _assets_index_pubspec
  log_info "Running Dart AST analysis..."
  _assets_index_dart
  log_success "Analysis complete"
}

# ── Git guard ──────────────────────────────────────────────────────────────────
_assets_git_guard() {
  if ! git diff --quiet || ! git diff --cached --quiet; then
    log_error "Git working tree is not clean. Commit or stash changes first."
    exit 1
  fi
}

# ==============================================================================
# COMMAND: check
# ==============================================================================
_assets_cmd_check() {
  [[ ! -d assets ]] && { log_error "No assets/ folder found. Run from the project root."; return 1; }

  log_section "Asset Analysis"
  echo ""

  _assets_build
  echo ""

  local tmp="$_ASSET_CACHE_DIR/unused.tmp"
  : > "$tmp"

  local total_scanned=0
  local total_unused=0
  local total_bytes=0

  while IFS= read -r asset; do
    total_scanned=$(( total_scanned + 1 ))
    if ! grep -Fq "$asset" "$_ASSETS_USED_INDEX"; then
      local size; size=$(_assets_size "$asset")
      local cat;  cat=$(_assets_category "$asset")
      echo "$asset|$size|$cat" >> "$tmp"
      total_unused=$(( total_unused + 1 ))
      total_bytes=$(( total_bytes + size ))
    fi
  done < <(_assets_list_files)

  if [[ $total_unused -eq 0 ]]; then
    log_success "All $total_scanned assets are referenced in code — nothing to clean."
    echo ""
    return 0
  fi

  printf "  ${_A_BOLD}%-10s  %-65s  %s${_A_RESET}\n" "TYPE" "PATH" "SIZE"
  printf "  %s\n" "--------  -----------------------------------------------------------------  --------"

  sort -t'|' -k2 -nr "$tmp" | while IFS='|' read -r asset size cat; do
    printf "  ${_A_DIM}%-10s${_A_RESET}  %-65s  %s\n" \
      "$cat" "$asset" "$(_assets_color_size "$size")"
  done

  echo ""

  local impact_label
  if   (( total_bytes > 1048576 )); then impact_label="${_A_RED}HIGH${_A_RESET}"
  elif (( total_bytes > 200000  )); then impact_label="${_A_YELLOW}MEDIUM${_A_RESET}"
  else                                   impact_label="${_A_GREEN}LOW${_A_RESET}"
  fi

  printf "  ${_A_BOLD}%-16s${_A_RESET} %s / %s unused\n" \
    "Scanned" "$total_unused" "$total_scanned"
  printf "  ${_A_BOLD}%-16s${_A_RESET} %s\n" \
    "Wasted space" "$(_assets_fmt_size "$total_bytes")"
  printf "  ${_A_BOLD}%-16s${_A_RESET} %b\n" \
    "Impact" "$impact_label"

  echo ""
  log_info "Run 'flut assets clean' to remove unused assets interactively."
  log_info "Run 'flut assets clean --dry-run' to preview, or --all to delete everything."
  echo ""
}

# ==============================================================================
# COMMAND: stats
# ==============================================================================
_assets_cmd_stats() {
  [[ ! -d assets ]] && { log_error "No assets/ folder found."; return 1; }

  log_section "Asset Stats"
  echo ""

  _assets_build
  echo ""

  local cat_tmp="$_ASSET_CACHE_DIR/cat_stats.txt"
  : > "$cat_tmp"

  while IFS= read -r asset; do
    local size; size=$(_assets_size "$asset")
    local cat;  cat=$(_assets_category "$asset")
    local is_used=0
    grep -Fq "$asset" "$_ASSETS_USED_INDEX" && is_used=1
    echo "$cat|$size|$is_used" >> "$cat_tmp"
  done < <(_assets_list_files)

  local total used unused
  total=$(wc -l < "$cat_tmp" | tr -d ' ')
  used=$(  grep "|1$" "$cat_tmp" 2>/dev/null | wc -l | tr -d ' ')
  unused=$(grep "|0$" "$cat_tmp" 2>/dev/null | wc -l | tr -d ' ')

  printf "  ${_A_BOLD}%-14s${_A_RESET} %s\n"                          "Total"  "$total"
  printf "  ${_A_BOLD}%-14s${_A_RESET} ${_A_GREEN}%s${_A_RESET}\n"   "Used"   "$used"
  printf "  ${_A_BOLD}%-14s${_A_RESET} ${_A_YELLOW}%s${_A_RESET}\n"  "Unused" "$unused"

  echo ""

  printf "  ${_A_BOLD}%-10s  %6s  %6s  %8s  %10s${_A_RESET}\n" \
    "CATEGORY" "TOTAL" "USED" "UNUSED" "SIZE"
  printf "  %s\n" "----------  ------  ------  --------  ----------"

  for cat in images icons fonts lottie other; do
    local c_total c_used c_unused c_size
    c_total=$(  grep "^${cat}|" "$cat_tmp" 2>/dev/null | wc -l | tr -d ' ')
    [[ "$c_total" -eq 0 ]] && continue

    c_used=$(   grep "^${cat}|.*|1$" "$cat_tmp" 2>/dev/null | wc -l | tr -d ' ')
    c_unused=$( grep "^${cat}|.*|0$" "$cat_tmp" 2>/dev/null | wc -l | tr -d ' ')
    c_size=$(   awk -F'|' -v cat="$cat" '$1==cat{s+=$2} END{print s+0}' "$cat_tmp")

    local unused_col="$c_unused"
    [[ "$c_unused" -gt 0 ]] && unused_col="${_A_YELLOW}${c_unused}${_A_RESET}"

    printf "  %-10s  %6s  %6s  %8b  %10s\n" \
      "$cat" "$c_total" "$c_used" "$unused_col" "$(_assets_fmt_size "$c_size")"
  done

  echo ""
}

# ==============================================================================
# COMMAND: audit
# ==============================================================================
_assets_cmd_audit() {
  [[ ! -d assets ]] && { log_error "No assets/ folder found."; return 1; }

  log_section "Asset Audit"
  echo ""

  _assets_build
  echo ""

  local used_count
  used_count=$(wc -l < "$_ASSETS_USED_INDEX" | tr -d ' ')
  log_info "$used_count asset reference(s) detected in Dart code"
  echo ""

  # ── Assets referenced in code but absent from pubspec ─────────────────────────
  local missing_pubspec=0
  while IFS= read -r asset; do
    [[ -z "$asset" ]] && continue
    if ! grep -Fq "$asset" "$_ASSETS_PUBSPEC_INDEX"; then
      if [[ $missing_pubspec -eq 0 ]]; then
        printf "  ${_A_BOLD}${_A_RED}Referenced in code, missing from pubspec.yaml:${_A_RESET}\n\n"
      fi
      printf "    ${_A_RED}%s${_A_RESET}\n" "$asset"
      missing_pubspec=$(( missing_pubspec + 1 ))
    fi
  done < "$_ASSETS_USED_INDEX"

  [[ $missing_pubspec -gt 0 ]] && echo ""

  # ── Entries declared in pubspec but not referenced anywhere ───────────────────
  local orphan_pubspec=0
  while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    if ! grep -Fq "$entry" "$_ASSETS_USED_INDEX"; then
      if [[ $orphan_pubspec -eq 0 ]]; then
        printf "  ${_A_BOLD}${_A_DIM}Declared in pubspec, not referenced in code:${_A_RESET}\n\n"
      fi
      printf "    ${_A_DIM}%s${_A_RESET}\n" "$entry"
      orphan_pubspec=$(( orphan_pubspec + 1 ))
    fi
  done < "$_ASSETS_PUBSPEC_INDEX"

  [[ $orphan_pubspec -gt 0 ]] && echo ""

  # ── Summary ────────────────────────────────────────────────────────────────────
  if [[ $missing_pubspec -eq 0 && $orphan_pubspec -eq 0 ]]; then
    log_success "pubspec.yaml and code references are in sync."
  else
    [[ $missing_pubspec  -gt 0 ]] && log_error   "$missing_pubspec asset(s) used in code but not declared in pubspec"
    [[ $orphan_pubspec   -gt 0 ]] && log_warning "$orphan_pubspec pubspec entry(ies) not referenced in Dart code"
  fi
  echo ""
}

# ==============================================================================
# COMMAND: clean
# ==============================================================================
_assets_cmd_clean() {
  local mode="interactive"

  for arg in "$@"; do
    case "$arg" in
      --dry-run) mode="dry"         ;;
      --all)     mode="all"         ;;
      *) log_error "Unknown option: $arg  (valid: --dry-run, --all)"; return 1 ;;
    esac
  done

  [[ ! -d assets ]] && { log_error "No assets/ folder found."; return 1; }

  [[ "$mode" != "dry" ]] && _assets_git_guard

  log_section "Asset Cleanup"
  echo ""

  _assets_build
  echo ""

  local list="$_ASSET_CACHE_DIR/delete.list"
  : > "$list"

  while IFS= read -r asset; do
    if ! grep -Fq "$asset" "$_ASSETS_USED_INDEX"; then
      echo "$asset" >> "$list"
    fi
  done < <(_assets_list_files)

  local count; count=$(wc -l < "$list" | tr -d ' ')

  if [[ "$count" -eq 0 ]]; then
    log_success "No unused assets found — nothing to delete."
    echo ""
    return 0
  fi

  log_info "$count unused asset(s) identified"
  echo ""

  # ── Dry run ────────────────────────────────────────────────────────────────────
  if [[ "$mode" == "dry" ]]; then
    printf "  ${_A_BOLD}${_A_YELLOW}Dry run — files that would be deleted:${_A_RESET}\n\n"
    local dry_bytes=0
    while IFS= read -r f; do
      local size; size=$(_assets_size "$f")
      dry_bytes=$(( dry_bytes + size ))
      printf "    %-65s  %s\n" "$f" "$(_assets_fmt_size "$size")"
    done < "$list"
    echo ""
    log_info "Total: $count file(s), $(_assets_fmt_size "$dry_bytes") would be freed."
    echo ""
    return 0
  fi

  # ── Delete all ─────────────────────────────────────────────────────────────────
  if [[ "$mode" == "all" ]]; then
    local total_freed=0
    while IFS= read -r f; do
      local size; size=$(_assets_size "$f")
      total_freed=$(( total_freed + size ))
      rm -f "$f"
      log_success "Deleted  $f"
    done < "$list"
    echo ""
    log_success "$count file(s) deleted — $(_assets_fmt_size "$total_freed") freed."
    echo ""
    return 0
  fi

  # ── Interactive ────────────────────────────────────────────────────────────────
  printf "  ${_A_BOLD}Reviewing $count candidate(s):${_A_RESET}\n\n"

  local deleted=0 freed=0
  while IFS= read -r f; do
    local size; size=$(_assets_size "$f")
    printf "  %s  ${_A_DIM}(%s)${_A_RESET}\n" "$f" "$(_assets_fmt_size "$size")"
    printf "  Delete? [y/N/q] "
    read -r r < /dev/tty
    case "$r" in
      y|Y)
        rm -f "$f"
        deleted=$(( deleted + 1 ))
        freed=$(( freed + size ))
        log_success "Deleted"
        ;;
      q|Q)
        echo ""
        log_info "Stopped. $deleted file(s) deleted."
        echo ""
        return 0
        ;;
      *)
        log_info "Skipped"
        ;;
    esac
    echo ""
  done < "$list"

  if [[ $deleted -gt 0 ]]; then
    log_success "$deleted file(s) deleted — $(_assets_fmt_size "$freed") freed."
  else
    log_info "No files deleted."
  fi
  echo ""
}

# ==============================================================================
# USAGE
# ==============================================================================
_assets_usage() {
  echo ""
  echo -e "  ${_A_BOLD}flut assets${_A_RESET}  Flutter Asset Analyzer"
  echo ""
  echo -e "  ${_A_CYAN}Usage:${_A_RESET}"
  echo "    flut assets <command> [options]"
  echo ""
  echo -e "  ${_A_CYAN}Commands:${_A_RESET}"
  echo "    check      Scan for unused assets, sorted by wasted size"
  echo "    stats      Breakdown by category (total / used / unused)"
  echo "    audit      Validate pubspec declarations vs code references"
  echo "    clean      Remove unused assets interactively or in bulk"
  echo ""
  echo -e "  ${_A_CYAN}Options (clean only):${_A_RESET}"
  echo "    --dry-run  Preview deletions without touching any file"
  echo "    --all      Delete all unused assets without prompting"
  echo ""
  echo -e "  ${_A_CYAN}Examples:${_A_RESET}"
  echo "    flut assets check"
  echo "    flut assets stats"
  echo "    flut assets audit"
  echo "    flut assets clean --dry-run"
  echo "    flut assets clean --all"
  echo ""
  echo -e "  ${_A_CYAN}Notes:${_A_RESET}"
  echo "    Powered by a hybrid Dart AST + regex engine."
  echo "    Translations (assets/translations/) are excluded from analysis."
  echo "    'clean' requires a clean git working tree (except with --dry-run)."
  echo ""
}

# ==============================================================================
# DISPATCHER
# ==============================================================================
cmd_assets() {
  local subcmd="${1:-}"
  shift || true

  case "$subcmd" in
    check) _assets_cmd_check "$@" ;;
    stats) _assets_cmd_stats "$@" ;;
    audit) _assets_cmd_audit "$@" ;;
    clean) _assets_cmd_clean "$@" ;;
    *)     _assets_usage ;;
  esac
}
