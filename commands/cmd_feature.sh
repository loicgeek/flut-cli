# ==============================================================================
#  COMMAND: feature
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

  log_section "Feature: $name  ->  $pascal"

  mkd "$BASE/business_logic"
  mkd "$BASE/data/models"
  mkd "$BASE/data/repositories"
  mkd "$BASE/presentation/router"
  mkd "$BASE/presentation/screens"
  mkd "$BASE/presentation/widgets"

  if [[ "$use_service" == true ]]; then
    mkd "$BASE/data/services"
  fi

  # --------------------------------------------------------------------------
  # Model — plain Dart class, zero codegen
  # --------------------------------------------------------------------------
  mkf_tpl "$BASE/data/models/${name}_model.dart" "feature/model.dart" Pascal="$pascal"

  # --------------------------------------------------------------------------
  # Service layer (optional)
  # When --service: the Repository delegates to the Service.
  # The Service handles multi-source orchestration, caching, or transformation.
  # Without --service: the Repository handles data access directly.
  # --------------------------------------------------------------------------
  if [[ "$use_service" == true ]]; then
    mkf_tpl "$BASE/data/services/${name}_service.dart" "feature/service.dart" Pascal="$pascal" name="$name"
  fi

  # --------------------------------------------------------------------------
  # Repository
  # Bloc/Cubit always injects the Repository.
  # When --service, the Repository injects and delegates to the Service.
  # --------------------------------------------------------------------------
  if [[ "$use_service" == true ]]; then
    mkf_tpl "$BASE/data/repositories/${name}_repository.dart" "feature/repository_service.dart" Pascal="$pascal" name="$name"
  else
    mkf_tpl "$BASE/data/repositories/${name}_repository.dart" "feature/repository.dart" Pascal="$pascal" name="$name"
  fi

  # --------------------------------------------------------------------------
  # State — plain sealed class, zero codegen
  # --------------------------------------------------------------------------
  mkf_tpl "$BASE/business_logic/${name}_state.dart" "feature/state.dart" Pascal="$pascal" name="$name"

  # --------------------------------------------------------------------------
  # Cubit or Bloc — always injects Repository
  # --------------------------------------------------------------------------
  if [[ "$use_bloc" == true ]]; then
    mkf_tpl "$BASE/business_logic/${name}_event.dart" "feature/event.dart" Pascal="$pascal"

    mkf_tpl "$BASE/business_logic/${name}_bloc.dart" "feature/bloc.dart" Pascal="$pascal" name="$name"
  else
    mkf_tpl "$BASE/business_logic/${name}_cubit.dart" "feature/cubit.dart" Pascal="$pascal" name="$name"
  fi

  # --------------------------------------------------------------------------
  # Feature router module
  # --------------------------------------------------------------------------
  local pkg_name="your_app"
  if [[ -f "pubspec.yaml" ]]; then
    local parsed
    parsed=$(grep -E '^name:' pubspec.yaml | head -1 | sed 's/name:[[:space:]]*//')
    [[ -n "$parsed" ]] && pkg_name="$parsed"
  fi

  mkf_tpl "$BASE/presentation/router/${name}_router_module.dart" "feature/router_module.dart" Pascal="$pascal" name="$name" pkg="$pkg_name"

  # --------------------------------------------------------------------------
  # Screen
  # --------------------------------------------------------------------------
  local bl_type bl_provide bl_import bl_retry
  if [[ "$use_bloc" == true ]]; then
    bl_type="${pascal}Bloc"
    bl_import="${name}_bloc.dart"
    bl_provide="create: (_) => sl<${pascal}Bloc>()..add(const ${pascal}Load())"
    bl_retry="context.read<${pascal}Bloc>().add(const ${pascal}Refresh())"
  else
    bl_type="${pascal}Cubit"
    bl_import="${name}_cubit.dart"
    bl_provide="create: (_) => sl<${pascal}Cubit>()..load()"
    bl_retry="context.read<${pascal}Cubit>().load()"
  fi

  mkf_tpl "$BASE/presentation/screens/${name}_screen.dart" "feature/screen.dart" Pascal="$pascal" blImport="$bl_import" blProvide="$bl_provide" blRetry="$bl_retry" blType="$bl_type" name="$name"

  # --------------------------------------------------------------------------
  # Post-generation checklist
  # --------------------------------------------------------------------------
  echo ""
  log_section "Checklist"

  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  if [[ "$use_service" == true ]]; then
    echo "     sl.registerSingleton<${pascal}Service>(${pascal}Service(/* data sources */));"
    echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  else
    echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  fi
  if [[ "$use_bloc" == true ]]; then
    echo "     sl.registerFactory<${pascal}Bloc>(() => ${pascal}Bloc(sl()));"
  else
    echo "     sl.registerFactory<${pascal}Cubit>(() => ${pascal}Cubit(sl()));"
  fi

  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     static const ${name}s = '/${name}s';"

  echo ""
  echo -e "  ${YELLOW}3. lib/core/router/app_router.dart${RESET}"
  echo "     AutoRoute(page: ${pascal}Route.page),"

  echo ""
  echo -e "  ${YELLOW}4. assets/translations/fr.json  &  en.json${RESET}"
  echo "     \"${name}\": { \"title\": \"...\", \"empty\": \"...\" }"

  echo ""
  echo -e "  ${YELLOW}5. presentation/router/${name}_router_module.dart${RESET}"
  echo "     Wire ${pascal}RouterModule into app_router.dart as a child route if needed."

  echo ""
  echo -e "  ${YELLOW}6. Code generation${RESET}"
  echo "     dart run build_runner build --delete-conflicting-outputs"

  echo ""
  echo -e "${BOLD}${GREEN}  Feature '$name' ready.${RESET}"
  echo ""
}
