# ==============================================================================
#  COMMAND: feature
#
#  Parses and validates arguments, then delegates file layout to the active
#  architecture's hooks (see architectures/<arch>/layout.sh).
# ==============================================================================
cmd_feature() {
  local name="${1:-}"
  local use_bloc=false
  local use_service=false

  # Parse all flags after the feature name
  shift || true
  for arg in "$@"; do
    case "$arg" in
      --bloc)    use_bloc=true ;;
      --service) use_service=true ;;
      *) log_error "Unknown flag: $arg"; echo "  Usage: flut feature <n> [--bloc] [--service]"; exit 1 ;;
    esac
  done

  if [[ -z "$name" ]]; then
    log_error "Feature name is required."
    echo "  Usage: flut feature <n> [--bloc] [--service]"
    exit 1
  fi

  if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Feature name must be snake_case."
    exit 1
  fi

  local pascal
  pascal=$(to_pascal "$name")
  local BASE="lib/features/$name"

  if [[ -d "$BASE" ]]; then
    log_error "Feature '$name' already exists."
    exit 1
  fi

  # Detect package name from pubspec.yaml
  local pkg_name="your_app"
  if [[ -f "pubspec.yaml" ]]; then
    local parsed
    parsed=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    [[ -n "$parsed" ]] && pkg_name="$parsed"
  fi

  _manifest_env
  _layout_env

  if ! declare -f arch_feature_scaffold &>/dev/null; then
    log_error "Architecture '$(_arch_current)' does not provide arch_feature_scaffold."
    exit 1
  fi

  # Hook contract (see architectures/<arch>/layout.sh)
  FLUT_FEATURE="$name"
  FLUT_FEATURE_PASCAL="$pascal"
  FLUT_NAME="$name"
  FLUT_PASCAL="$pascal"
  FLUT_BASE="$BASE"
  FLUT_PKG="$pkg_name"
  FLUT_USE_BLOC="$use_bloc"
  FLUT_USE_SERVICE="$use_service"

  log_section "Feature: $name  ->  $pascal"

  arch_feature_scaffold

  # --------------------------------------------------------------------------
  # Post-generation checklist
  # --------------------------------------------------------------------------
  echo ""
  log_section "Checklist"

  if declare -f arch_feature_checklist &>/dev/null; then
    arch_feature_checklist
  fi

  echo ""
  echo -e "${BOLD}${GREEN}  Feature '$name' ready.${RESET}"
  echo ""
}
