#!/usr/bin/env bash
# =============================================================================
#  flut — Flutter project scaffold CLI
#
#  Usage:
#    flut init                                  Init full lib/ scaffold + install packages
#    flut feature <n>                        Add a feature with Cubit
#    flut feature <n> --bloc               Add a feature with Bloc
#    flut feature <n> --service            Add a feature with a Service layer
#    flut feature <n> --bloc --service     Bloc + Service layer
#
#  Code generation: AutoRoute ONLY.
#  Models      → plain Dart class, manual fromJson/toJson
#  State       → plain sealed class
#  DI          → manual GetIt registration (no injectable)
#
#  Architecture: controlled per project via flut.json (written by `flut init`).
#  Default: ntech. Installed profiles live in architectures/<name>/.
# =============================================================================

set -euo pipefail

# Resolve the real script directory, following symlinks (works on macOS + Linux).
_flut_src="${BASH_SOURCE[0]:-$0}"
while [[ -L "$_flut_src" ]]; do
  _flut_src_dir="$(cd -P "$(dirname "$_flut_src")" && pwd)"
  _flut_src="$(readlink "$_flut_src")"
  [[ "$_flut_src" != /* ]] && _flut_src="$_flut_src_dir/$_flut_src"
done
_FLUT_SCRIPT_DIR="$(cd -P "$(dirname "$_flut_src")" && pwd)"
unset _flut_src _flut_src_dir

FLUT_VERSION="$(tr -d '[:space:]' < "$_FLUT_SCRIPT_DIR/VERSION" 2>/dev/null || true)"
FLUT_VERSION="${FLUT_VERSION:-dev}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${CYAN}  ->  ${RESET} $1"; }
log_success() { echo -e "${GREEN}  ok  ${RESET} $1"; }
log_warning() { echo -e "${YELLOW}  !!  ${RESET} $1"; }
log_error()   { echo -e "${RED}  xx  ${RESET} $1"; }
log_section() { echo -e "\n${BOLD}${CYAN}>> $1${RESET}"; }

# Load command modules (one file per command)
for _flut_module in "$_FLUT_SCRIPT_DIR"/commands/cmd_*.sh; do
  # shellcheck source=/dev/null
  [[ -f "$_flut_module" ]] && source "$_flut_module"
done
unset _flut_module

mkf() {
  local path="$1" content="$2"
  mkdir -p "$(dirname "$path")"
  if [[ -f "$path" ]]; then
    log_warning "exists - skipped: $path"
  else
    printf '%s' "$content" > "$path"
    log_success "$path"
  fi
}

mkd() { mkdir -p "$1"; log_info "dir: $1"; }

to_pascal() {
  echo "$1" | awk -F'_' '{
    result=""
    for(i=1; i<=NF; i++) {
      result = result toupper(substr($i,1,1)) substr($i,2)
    }
    print result
  }'
}

# ==============================================================================
#  ARCHITECTURE CONFIG
#  Per-project architecture lives in ./flut.json; installed profiles are
#  directories under $FLUT_ARCH_DIR. Default profile: ntech.
# ==============================================================================

FLUT_CONFIG_FILE="flut.json"
FLUT_ARCH_DIR="$_FLUT_SCRIPT_DIR/architectures"
FLUT_DEFAULT_ARCH="ntech"

# List installed architecture profile names (one per line)
_arch_list() {
  local archs=() d
  for d in "$FLUT_ARCH_DIR"/*/; do
    [[ -d "$d" ]] && archs+=("$(basename "$d")")
  done
  printf '%s\n' "${archs[@]}"
}

# Read the active architecture from ./flut.json (default: ntech when absent)
_arch_current() {
  if [[ -f "$FLUT_CONFIG_FILE" ]]; then
    local arch
    arch="$(grep -oE '"architecture"[[:space:]]*:[[:space:]]*"[^"]+"' "$FLUT_CONFIG_FILE" 2>/dev/null \
      | head -n 1 | sed -E 's/.*"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/')"
    if [[ -n "$arch" ]]; then
      echo "$arch"
      return
    fi
  fi
  echo "$FLUT_DEFAULT_ARCH"
}

# Write the active architecture to ./flut.json
_arch_write() {
  local arch="$1"
  printf '{\n  "architecture": "%s"\n}\n' "$arch" > "$FLUT_CONFIG_FILE"
  log_success "$FLUT_CONFIG_FILE"
}

# True if the named architecture is installed
_arch_exists() {
  local arch="$1"
  [[ -n "$arch" && -d "$FLUT_ARCH_DIR/$arch" ]]
}

# Load an architecture's manifest metadata (ARCH_NAME, ARCH_DESCRIPTION)
_arch_manifest() {
  ARCH_NAME=""
  ARCH_DESCRIPTION=""
  if [[ -f "$FLUT_ARCH_DIR/$1/manifest.sh" ]]; then
    # shellcheck source=/dev/null
    source "$FLUT_ARCH_DIR/$1/manifest.sh"
  fi
  if [[ -z "$ARCH_NAME" ]]; then
    ARCH_NAME="$1"
  fi
}

usage() {
  echo ""
  echo -e "${BOLD}flut${RESET} v${FLUT_VERSION} - Flutter scaffold CLI"
  echo ""
  echo -e "  ${CYAN}flut init${RESET}                                  Init full lib/ scaffold"
  echo -e "  ${CYAN}flut init --architecture <n>${RESET}          Init with a specific architecture"
  echo -e "  ${CYAN}flut architecture${RESET}                           List installed architectures"
  echo -e "  ${CYAN}flut feature <n>${RESET}                        Add feature (Cubit)"
  echo -e "  ${CYAN}flut feature <n> --bloc${RESET}              Add feature (Bloc)"
  echo -e "  ${CYAN}flut feature <n> --service${RESET}           Add feature with Service layer"
  echo -e "  ${CYAN}flut feature <n> --bloc --service${RESET}    Bloc + Service layer"
  echo -e "  ${CYAN}flut generate${RESET}                              Generate individual components"
  echo -e "  ${CYAN}flut check${RESET}                                  Audit architecture conventions"
  echo -e "  ${CYAN}flut doctor${RESET}                                 Check project health"
  echo -e "  ${CYAN}flut clean${RESET}                                  Remove generated files (.gr.dart, .g.dart)"
  echo -e "  ${CYAN}flut clean --rebuild${RESET}                    Remove then regenerate via build_runner"
  echo -e "  ${CYAN}flut upgrade${RESET}                               Upgrade flut-cli to latest version"
  echo -e "  ${CYAN}flut assets check${RESET}                          Detect unused assets"
  echo -e "  ${CYAN}flut assets stats${RESET}                          Statistics by category"
  echo -e "  ${CYAN}flut assets clean [--all] [--dry-run]${RESET}  Delete unused assets"
  echo ""
  echo "  Examples:"
  echo "    flut init"
  echo "    flut init --architecture clean"
  echo "    flut architecture"
  echo "    flut architecture --set clean"
  echo "    flut feature auth"
  echo "    flut feature payment --bloc"
  echo "    flut feature order --service"
  echo "    flut feature checkout --bloc --service"
  echo "    flut generate model auth"
  echo "    flut generate model auth login_request"
  echo "    flut generate screen auth"
  echo "    flut generate repository auth"
  echo "    flut generate cubit auth"
  echo "    flut generate bloc auth"
  echo "    flut check"
  echo "    flut doctor"
  echo "    flut upgrade"
  echo "    flut assets check"
  echo "    flut assets stats"
  echo "    flut assets clean"
  echo "    flut assets clean --all"
  echo ""
}

case "${1:-}" in
  init)            shift; cmd_init "$@" ;;
  architecture)    shift; cmd_architecture "$@" ;;
  feature)         shift; cmd_feature "$@" ;;
  generate)        shift; cmd_generate "$@" ;;
  check)           cmd_check ;;
  doctor)          cmd_doctor ;;
  clean)           shift; cmd_clean "$@" ;;
  assets)
    if declare -f cmd_assets &>/dev/null; then
      shift; cmd_assets "$@"
    else
      log_error "assets module not found. Try: flut upgrade"; exit 1
    fi ;;
  upgrade)         cmd_upgrade ;;
  -h|--help|"")    usage ;;
  --version|-v)    echo "flut v${FLUT_VERSION}" ;;
  *) log_error "Unknown command: $1"; usage; exit 1 ;;
esac
