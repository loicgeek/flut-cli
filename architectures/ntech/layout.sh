# =============================================================================
#  NTECH-SERVICES layout hooks
#
#  A profile owns *where* files go; the command modules own argument parsing,
#  validation and reporting. Commands export the following before calling a
#  hook:
#
#    FLUT_FEATURE        feature name (snake_case)
#    FLUT_FEATURE_PASCAL feature name (PascalCase)
#    FLUT_NAME           component name (snake_case; == FLUT_FEATURE for `feature`)
#    FLUT_PASCAL         component name (PascalCase)
#    FLUT_BASE           lib/features/<feature>
#    FLUT_PKG            package name read from pubspec.yaml
#    FLUT_USE_BLOC       true|false  (feature only)
#    FLUT_USE_SERVICE    true|false  (feature only)
#
#  Hooks: arch_feature_scaffold, arch_feature_checklist, arch_generate_<type>,
#  arch_init_extra. ARCH_GENERATE_TYPES lists the supported `generate` types.
# =============================================================================

ARCH_GENERATE_TYPES=(model screen repository cubit bloc)

# ── feature ──────────────────────────────────────────────────────────────────
arch_feature_scaffold() {
  local name="$FLUT_NAME" pascal="$FLUT_PASCAL" BASE="$FLUT_BASE"

  mkd "$BASE/business_logic"
  mkd "$BASE/data/models"
  mkd "$BASE/data/repositories"
  mkd "$BASE/presentation/router"
  mkd "$BASE/presentation/screens"
  mkd "$BASE/presentation/widgets"

  if [[ "$FLUT_USE_SERVICE" == true ]]; then
    mkd "$BASE/data/services"
  fi

  # Model — plain Dart class, zero codegen
  mkf_tpl "$BASE/data/models/${name}_model.dart" "feature/model.dart" Pascal="$pascal"

  # Service layer (optional)
  # When --service: the Repository delegates to the Service. The Service
  # handles multi-source orchestration, caching, or transformation.
  # Without --service: the Repository handles data access directly.
  if [[ "$FLUT_USE_SERVICE" == true ]]; then
    mkf_tpl "$BASE/data/services/${name}_service.dart" "feature/service.dart" Pascal="$pascal" name="$name"
  fi

  # Repository — Bloc/Cubit always injects the Repository.
  if [[ "$FLUT_USE_SERVICE" == true ]]; then
    mkf_tpl "$BASE/data/repositories/${name}_repository.dart" "feature/repository_service.dart" Pascal="$pascal" name="$name"
  else
    mkf_tpl "$BASE/data/repositories/${name}_repository.dart" "feature/repository.dart" Pascal="$pascal" name="$name"
  fi

  # State — plain sealed class, zero codegen
  mkf_tpl "$BASE/business_logic/${name}_state.dart" "feature/state.dart" Pascal="$pascal" name="$name"

  # Cubit or Bloc — always injects Repository
  if [[ "$FLUT_USE_BLOC" == true ]]; then
    mkf_tpl "$BASE/business_logic/${name}_event.dart" "feature/event.dart" Pascal="$pascal"
    mkf_tpl "$BASE/business_logic/${name}_bloc.dart" "feature/bloc.dart" Pascal="$pascal" name="$name"
  else
    mkf_tpl "$BASE/business_logic/${name}_cubit.dart" "feature/cubit.dart" Pascal="$pascal" name="$name"
  fi

  # Feature router module
  mkf_tpl "$BASE/presentation/router/${name}_router_module.dart" "feature/router_module.dart" Pascal="$pascal" name="$name" pkg="$FLUT_PKG"

  # Screen
  local bl_type bl_provide bl_import bl_retry
  if [[ "$FLUT_USE_BLOC" == true ]]; then
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
}

arch_feature_checklist() {
  local name="$FLUT_NAME" pascal="$FLUT_PASCAL"

  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  if [[ "$FLUT_USE_SERVICE" == true ]]; then
    echo "     sl.registerSingleton<${pascal}Service>(${pascal}Service(/* data sources */));"
    echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  else
    echo "     sl.registerSingleton<${pascal}Repository>(${pascal}Repository(sl()));"
  fi
  if [[ "$FLUT_USE_BLOC" == true ]]; then
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
}

# ── generate ─────────────────────────────────────────────────────────────────
arch_generate_model() {
  mkf_tpl "$FLUT_BASE/data/models/${FLUT_NAME}_model.dart" "generate/model.dart" Pascal="$FLUT_PASCAL"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_model"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     // ${FLUT_PASCAL}Model used by ${FLUT_FEATURE_PASCAL}Repository"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     // Add API endpoint for ${FLUT_NAME}s if needed"
  echo ""
}

arch_generate_screen() {
  mkf_tpl "$FLUT_BASE/presentation/screens/${FLUT_NAME}_screen.dart" "generate/screen.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_screen"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/router/app_router.dart${RESET}"
  echo "     AutoRoute(page: ${FLUT_PASCAL}Route.page),"
  echo ""
  echo -e "  ${YELLOW}2. assets/translations/fr.json  &  en.json${RESET}"
  echo "     \"${FLUT_NAME}\": { \"title\": \"...\", \"empty\": \"...\" }"
  echo ""
}

arch_generate_repository() {
  mkf_tpl "$FLUT_BASE/data/repositories/${FLUT_NAME}_repository.dart" "generate/repository.dart" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_repository"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerSingleton<${FLUT_PASCAL}Repository>(${FLUT_PASCAL}Repository(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     static const ${FLUT_NAME}s = '/${FLUT_NAME}s';"
  echo ""
}

arch_generate_cubit() {
  local state_file="$FLUT_BASE/business_logic/${FLUT_FEATURE}_state.dart"
  if [[ ! -f "$state_file" ]]; then
    mkf_tpl "$state_file" "generate/state.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL"
  fi

  mkf_tpl "$FLUT_BASE/business_logic/${FLUT_NAME}_cubit.dart" "generate/cubit.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_cubit"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerFactory<${FLUT_PASCAL}Cubit>(() => ${FLUT_PASCAL}Cubit(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/router/app_router.dart${RESET}"
  echo "     Add a route that provides ${FLUT_PASCAL}Cubit"
  echo ""
}

arch_generate_bloc() {
  local state_file="$FLUT_BASE/business_logic/${FLUT_FEATURE}_state.dart"
  if [[ ! -f "$state_file" ]]; then
    mkf_tpl "$state_file" "generate/state.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL"
  fi

  mkf_tpl "$FLUT_BASE/business_logic/${FLUT_NAME}_event.dart" "generate/event.dart" Pascal="$FLUT_PASCAL"

  mkf_tpl "$FLUT_BASE/business_logic/${FLUT_NAME}_bloc.dart" "generate/bloc.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_bloc"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerFactory<${FLUT_PASCAL}Bloc>(() => ${FLUT_PASCAL}Bloc(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/router/app_router.dart${RESET}"
  echo "     Add a route that provides ${FLUT_PASCAL}Bloc"
  echo ""
}
