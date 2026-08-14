# ==============================================================================
#  COMMAND: generate — Individual component generators
#
#  The supported types and the files they produce come from the active
#  architecture (ARCH_GENERATE_TYPES + arch_generate_<type> in layout.sh).
# ==============================================================================

cmd_generate() {
  local type="${1:-}"
  local feature="${2:-}"
  local name="${3:-}"

  # If name not given, default to feature name
  if [[ -z "$name" ]]; then
    name="$feature"
  fi

  _manifest_env
  _layout_env

  local types="${ARCH_GENERATE_TYPES[*]:-}"
  local types_pipe="${types// /|}"

  if [[ -z "$type" || -z "$feature" ]]; then
    log_error "Usage: flut generate <${types_pipe}> <feature> [name]"
    echo ""
    echo "  Examples:"
    local t
    for t in "${ARCH_GENERATE_TYPES[@]}"; do
      echo "    flut generate $t auth"
    done
    echo "    flut generate ${ARCH_GENERATE_TYPES[0]} auth login_request   # custom component name"
    exit 1
  fi

  if [[ ! "$feature" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Feature name must be snake_case."
    exit 1
  fi

  if [[ ! "$name" =~ ^[a-z][a-z0-9_]*$ ]]; then
    log_error "Component name must be snake_case."
    exit 1
  fi

  local BASE="lib/features/$feature"
  if [[ ! -d "$BASE" ]]; then
    log_error "Feature '$feature' does not exist at $BASE"
    log_info "Create it first with: flut feature $feature"
    exit 1
  fi

  local pascal
  pascal=$(to_pascal "$name")
  local feature_pascal
  feature_pascal=$(to_pascal "$feature")

  # Detect package name from pubspec.yaml
  local pkg_name="your_app"
  if [[ -f "pubspec.yaml" ]]; then
    local parsed
    parsed=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    [[ -n "$parsed" ]] && pkg_name="$parsed"
  fi

  # Hook contract (see architectures/<arch>/layout.sh)
  FLUT_FEATURE="$feature"
  FLUT_FEATURE_PASCAL="$feature_pascal"
  FLUT_NAME="$name"
  FLUT_PASCAL="$pascal"
  FLUT_BASE="$BASE"
  FLUT_PKG="$pkg_name"

  local supported=false t
  for t in "${ARCH_GENERATE_TYPES[@]}"; do
    [[ "$t" == "$type" ]] && supported=true && break
  done

  if [[ "$supported" != true ]] || ! declare -f "arch_generate_$type" &>/dev/null; then
    log_error "Unknown type: $type"
    echo "  Valid types: ${types// /, }"
    exit 1
  fi

  "arch_generate_$type"
}
