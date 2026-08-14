# ==============================================================================
#  COMMAND: generate — Individual component generators
# ==============================================================================

cmd_generate() {
  local type="${1:-}"
  local feature="${2:-}"
  local name="${3:-}"

  # If name not given, default to feature name
  if [[ -z "$name" ]]; then
    name="$feature"
  fi

  if [[ -z "$type" || -z "$feature" ]]; then
    log_error "Usage: flut generate <model|screen|repository|cubit|bloc> <feature> [name]"
    echo ""
    echo "  Examples:"
    echo "    flut generate model auth"
    echo "    flut generate model auth login_request"
    echo "    flut generate screen auth"
    echo "    flut generate repository auth"
    echo "    flut generate cubit auth"
    echo "    flut generate bloc auth"
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

  case "$type" in
    model)
      _gen_model
      ;;
    screen)
      _gen_screen
      ;;
    repository)
      _gen_repository
      ;;
    cubit)
      _gen_cubit
      ;;
    bloc)
      _gen_bloc
      ;;
    *)
      log_error "Unknown type: $type"
      echo "  Valid types: model, screen, repository, cubit, bloc"
      exit 1
      ;;
  esac
}

# ── Generate: model ────────────────────────────────────────────────────────────
_gen_model() {
  mkf_tpl "$BASE/data/models/${name}_model.dart" "generate/model.dart" Pascal="$pascal"
  echo ""
  log_section "Next steps for ${feature}.${name}_model"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     // ${pascal}Model used by ${feature_pascal}Repository"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     // Add API endpoint for ${name}s if needed"
  echo ""
}

# ── Generate: screen ───────────────────────────────────────────────────────────
_gen_screen() {
  mkf_tpl "$BASE/presentation/screens/${name}_screen.dart" "generate/screen.dart" Feature="$feature" FeaturePascal="$feature_pascal" Pascal="$pascal" name="$name"
  echo ""
  log_section "Next steps for ${feature}.${name}_screen"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/router/app_router.dart${RESET}"
  echo "     AutoRoute(page: ${pascal}Route.page),"
  echo ""
  echo -e "  ${YELLOW}2. assets/translations/fr.json  &  en.json${RESET}"
  echo "     \"${name}\": { \"title\": \"...\", \"empty\": \"...\" }"
  echo ""
}

# ── Generate: repository ───────────────────────────────────────────────────────
_gen_repository() {
  mkf_tpl "$BASE/data/repositories/${name}_repository.dart" "generate/repository.dart" Pascal="$pascal" name="$name"
  echo ""
  log_section "Next steps for ${feature}.${name}_repository"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     static const ${name}s = '/${name}s';"
  echo ""
}

# ── Generate: cubit ────────────────────────────────────────────────────────────
_gen_cubit() {
  # Check if state file exists, create if not
  local state_file="$BASE/business_logic/${feature}_state.dart"
  if [[ ! -f "$state_file" ]]; then
    mkf_tpl "$state_file" "generate/state.dart" Feature="$feature" FeaturePascal="$feature_pascal"
  fi

  mkf_tpl "$BASE/business_logic/${name}_cubit.dart" "generate/cubit.dart" Feature="$feature" FeaturePascal="$feature_pascal" Pascal="$pascal" name="$name"
  echo ""
  log_section "Next steps for ${feature}.${name}_cubit"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerFactory<${pascal}Cubit>(() => ${pascal}Cubit(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/router/app_router.dart${RESET}"
  echo "     Add a route that provides ${pascal}Cubit"
  echo ""
}

# ── Generate: bloc ─────────────────────────────────────────────────────────────
_gen_bloc() {
  # Check if state file exists, create if not
  local state_file="$BASE/business_logic/${feature}_state.dart"
  if [[ ! -f "$state_file" ]]; then
    mkf_tpl "$state_file" "generate/state.dart" Feature="$feature" FeaturePascal="$feature_pascal"
  fi

  mkf_tpl "$BASE/business_logic/${name}_event.dart" "generate/event.dart" Pascal="$pascal"

  mkf_tpl "$BASE/business_logic/${name}_bloc.dart" "generate/bloc.dart" Feature="$feature" FeaturePascal="$feature_pascal" Pascal="$pascal" name="$name"
  echo ""
  log_section "Next steps for ${feature}.${name}_bloc"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerFactory<${pascal}Bloc>(() => ${pascal}Bloc(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/router/app_router.dart${RESET}"
  echo "     Add a route that provides ${pascal}Bloc"
  echo ""
}
