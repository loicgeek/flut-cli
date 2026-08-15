# =============================================================================
#  Clean Architecture layout hooks
#
#  Feature slice = one vertical cut through three layers:
#
#    domain/       entities, repository interfaces, use cases   (pure Dart)
#    data/         models, data sources, repository impls       (Dio, JSON)
#    presentation/ bloc|cubit, screens, router, widgets         (Flutter)
#
#  Dependencies point inwards only: presentation -> domain <- data.
#  See architectures/ntech/layout.sh for the hook contract.
# =============================================================================

# Consumed by cmd_generate.sh
# shellcheck disable=SC2034
ARCH_GENERATE_TYPES=(entity usecase model datasource repository screen cubit bloc)

# ── init ─────────────────────────────────────────────────────────────────────
arch_init_extra() {
  log_section "Clean Architecture"
  mkd "lib/core/usecase"
  mkf_tpl "lib/core/usecase/usecase.dart" "init/core/usecase/usecase.dart"
}

# ── shared helpers ───────────────────────────────────────────────────────────
# A generated component is only useful if what it depends on exists, so each
# generator creates its missing dependencies (same idea as `generate cubit`
# creating the state file when absent).

_clean_ensure_entity() {
  local f="$FLUT_BASE/domain/entities/${FLUT_NAME}.dart"
  [[ -f "$f" ]] || mkf_tpl "$f" "feature/entity.dart" Pascal="$FLUT_PASCAL"
}

_clean_ensure_repository_interface() {
  _clean_ensure_entity
  local f="$FLUT_BASE/domain/repositories/${FLUT_NAME}_repository.dart"
  [[ -f "$f" ]] || mkf_tpl "$f" "feature/repository_interface.dart" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
}

_clean_ensure_usecase() {
  _clean_ensure_repository_interface
  local f="$FLUT_BASE/domain/usecases/${FLUT_NAME}_usecase.dart"
  [[ -f "$f" ]] || mkf_tpl "$f" "feature/usecase.dart" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
}

_clean_ensure_model() {
  _clean_ensure_entity
  local f="$FLUT_BASE/data/models/${FLUT_NAME}_model.dart"
  [[ -f "$f" ]] || mkf_tpl "$f" "feature/model.dart" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
}

_clean_ensure_datasource() {
  _clean_ensure_model
  local f="$FLUT_BASE/data/datasources/${FLUT_NAME}_remote_datasource.dart"
  [[ -f "$f" ]] || mkf_tpl "$f" "feature/datasource.dart" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
}

# A generated cubit/bloc shares the feature's state, so it reads the feature's
# use case - a component-named one would return the wrong entity type.
_clean_ensure_feature_usecase() {
  local e="$FLUT_BASE/domain/entities/${FLUT_FEATURE}.dart"
  [[ -f "$e" ]] || mkf_tpl "$e" "feature/entity.dart" Pascal="$FLUT_FEATURE_PASCAL"

  local r="$FLUT_BASE/domain/repositories/${FLUT_FEATURE}_repository.dart"
  [[ -f "$r" ]] || mkf_tpl "$r" "feature/repository_interface.dart" Pascal="$FLUT_FEATURE_PASCAL" name="$FLUT_FEATURE"

  local u="$FLUT_BASE/domain/usecases/${FLUT_FEATURE}_usecase.dart"
  [[ -f "$u" ]] || mkf_tpl "$u" "feature/usecase.dart" Pascal="$FLUT_FEATURE_PASCAL" name="$FLUT_FEATURE"
}

_clean_ensure_feature_state() {
  local f="$FLUT_BASE/presentation/bloc/${FLUT_FEATURE}_state.dart"
  [[ -f "$f" ]] || mkf_tpl "$f" "generate/state.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL"
}

# State-manager wiring for the screen template
_clean_bl_vars() {
  if [[ "${FLUT_USE_BLOC:-false}" == true ]]; then
    bl_type="${FLUT_PASCAL}Bloc"
    bl_import="${FLUT_NAME}_bloc.dart"
    bl_provide="create: (_) => sl<${FLUT_PASCAL}Bloc>()..add(const ${FLUT_PASCAL}Load())"
    bl_retry="context.read<${FLUT_PASCAL}Bloc>().add(const ${FLUT_PASCAL}Refresh())"
  else
    bl_type="${FLUT_PASCAL}Cubit"
    bl_import="${FLUT_NAME}_cubit.dart"
    bl_provide="create: (_) => sl<${FLUT_PASCAL}Cubit>()..load()"
    bl_retry="context.read<${FLUT_PASCAL}Cubit>().load()"
  fi
}

# ── feature ──────────────────────────────────────────────────────────────────
arch_feature_scaffold() {
  local name="$FLUT_NAME" pascal="$FLUT_PASCAL" BASE="$FLUT_BASE"

  add_api_endpoint "$name"

  if [[ "$FLUT_USE_SERVICE" == true ]]; then
    log_warning "--service has no effect in clean — data/datasources/ already isolates data access."
  fi

  mkd "$BASE/domain/entities"
  mkd "$BASE/domain/repositories"
  mkd "$BASE/domain/usecases"
  mkd "$BASE/data/datasources"
  mkd "$BASE/data/models"
  mkd "$BASE/data/repositories"
  mkd "$BASE/presentation/bloc"
  mkd "$BASE/presentation/router"
  mkd "$BASE/presentation/screens"
  mkd "$BASE/presentation/widgets"

  # domain — pure Dart, no outward dependencies
  mkf_tpl "$BASE/domain/entities/${name}.dart" "feature/entity.dart" Pascal="$pascal"
  mkf_tpl "$BASE/domain/repositories/${name}_repository.dart" "feature/repository_interface.dart" Pascal="$pascal" name="$name"
  mkf_tpl "$BASE/domain/usecases/${name}_usecase.dart" "feature/usecase.dart" Pascal="$pascal" name="$name"

  # data — implements the domain contract
  mkf_tpl "$BASE/data/models/${name}_model.dart" "feature/model.dart" Pascal="$pascal" name="$name"
  mkf_tpl "$BASE/data/datasources/${name}_remote_datasource.dart" "feature/datasource.dart" Pascal="$pascal" name="$name"
  mkf_tpl "$BASE/data/repositories/${name}_repository_impl.dart" "feature/repository_impl.dart" Pascal="$pascal" name="$name"

  # presentation — depends on the use case only
  mkf_tpl "$BASE/presentation/bloc/${name}_state.dart" "feature/state.dart" Pascal="$pascal" name="$name"

  if [[ "$FLUT_USE_BLOC" == true ]]; then
    mkf_tpl "$BASE/presentation/bloc/${name}_event.dart" "feature/event.dart" Pascal="$pascal"
    mkf_tpl "$BASE/presentation/bloc/${name}_bloc.dart" "feature/bloc.dart" Pascal="$pascal" name="$name"
  else
    mkf_tpl "$BASE/presentation/bloc/${name}_cubit.dart" "feature/cubit.dart" Pascal="$pascal" name="$name"
  fi

  mkf_tpl "$BASE/presentation/router/${name}_router_module.dart" "feature/router_module.dart" Pascal="$pascal" name="$name" pkg="$FLUT_PKG"

  local bl_type bl_provide bl_import bl_retry
  _clean_bl_vars
  mkf_tpl "$BASE/presentation/screens/${name}_screen.dart" "feature/screen.dart" Pascal="$pascal" blImport="$bl_import" blProvide="$bl_provide" blRetry="$bl_retry" blType="$bl_type" name="$name"
}

arch_feature_checklist() {
  local name="$FLUT_NAME" pascal="$FLUT_PASCAL"

  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     // register outwards-in: data source -> repository -> use case -> state"
  echo "     sl.registerSingleton<${pascal}RemoteDataSource>(${pascal}RemoteDataSourceImpl(sl()));"
  echo "     sl.registerSingleton<${pascal}Repository>(${pascal}RepositoryImpl(sl()));"
  echo "     sl.registerSingleton<${pascal}UseCase>(${pascal}UseCase(sl()));"
  if [[ "$FLUT_USE_BLOC" == true ]]; then
    echo "     sl.registerFactory<${pascal}Bloc>(() => ${pascal}Bloc(sl()));"
  else
    echo "     sl.registerFactory<${pascal}Cubit>(() => ${pascal}Cubit(sl()));"
  fi

  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     registered: static const ${name}s = '/${name}s';  (adjust if the API differs)"

  echo ""
  echo -e "  ${YELLOW}3. lib/core/router/app_router.dart${RESET}"
  echo "     AutoRoute(page: ${pascal}Route.page),"

  echo ""
  echo -e "  ${YELLOW}4. assets/translations/fr.json  &  en.json${RESET}"
  echo "     \"${name}\": { \"title\": \"...\", \"empty\": \"...\" }"

  echo ""
  echo -e "  ${YELLOW}5. domain/entities/${name}.dart  &  data/models/${name}_model.dart${RESET}"
  echo "     Add the real fields to the entity, then mirror them in the model."

  echo ""
  echo -e "  ${YELLOW}6. Code generation${RESET}"
  echo "     dart run build_runner build --delete-conflicting-outputs"
}

# ── generate ─────────────────────────────────────────────────────────────────
arch_generate_entity() {
  mkf_tpl "$FLUT_BASE/domain/entities/${FLUT_NAME}.dart" "feature/entity.dart" Pascal="$FLUT_PASCAL"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME} (entity)"
  echo ""
  echo -e "  ${YELLOW}1. domain/entities/${FLUT_NAME}.dart${RESET}"
  echo "     Add the fields that describe this concept — no JSON, no Flutter."
  echo ""
  echo -e "  ${YELLOW}2. flut generate model ${FLUT_FEATURE} ${FLUT_NAME}${RESET}"
  echo "     Create the data-layer model that serializes it."
  echo ""
}

arch_generate_usecase() {
  _clean_ensure_usecase
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_usecase"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerSingleton<${FLUT_PASCAL}UseCase>(${FLUT_PASCAL}UseCase(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. domain/usecases/${FLUT_NAME}_usecase.dart${RESET}"
  echo "     Put the business rules in call(); keep it independent of Dio."
  echo ""
}

arch_generate_model() {
  _clean_ensure_model
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_model"
  echo ""
  echo -e "  ${YELLOW}1. data/models/${FLUT_NAME}_model.dart${RESET}"
  echo "     Mirror the entity fields in fromJson/toJson."
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     // Add the endpoint for ${FLUT_NAME}s if needed"
  echo ""
}

arch_generate_datasource() {
  add_api_endpoint "$FLUT_NAME"
  _clean_ensure_datasource
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_remote_datasource"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerSingleton<${FLUT_PASCAL}RemoteDataSource>(${FLUT_PASCAL}RemoteDataSourceImpl(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. lib/core/api/api_endpoints.dart${RESET}"
  echo "     registered: static const ${FLUT_NAME}s = '/${FLUT_NAME}s';  (adjust if the API differs)"
  echo ""
}

arch_generate_repository() {
  add_api_endpoint "$FLUT_NAME"
  _clean_ensure_datasource
  _clean_ensure_repository_interface
  mkf_tpl "$FLUT_BASE/data/repositories/${FLUT_NAME}_repository_impl.dart" "feature/repository_impl.dart" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
  echo ""
  log_section "Next steps for ${FLUT_FEATURE}.${FLUT_NAME}_repository"
  echo ""
  echo -e "  ${YELLOW}1. lib/core/di/service_locator.dart${RESET}"
  echo "     sl.registerSingleton<${FLUT_PASCAL}Repository>(${FLUT_PASCAL}RepositoryImpl(sl()));"
  echo ""
  echo -e "  ${YELLOW}2. domain/repositories/${FLUT_NAME}_repository.dart${RESET}"
  echo "     Declare operations on the interface first, then implement them."
  echo ""
}

# Bind a generated screen to the state manager the feature actually uses
_clean_feature_bl_vars() {
  if [[ -f "$FLUT_BASE/presentation/bloc/${FLUT_FEATURE}_bloc.dart" ]]; then
    bl_type="${FLUT_FEATURE_PASCAL}Bloc"
    bl_import="${FLUT_FEATURE}_bloc.dart"
    bl_provide="create: (_) => sl<${FLUT_FEATURE_PASCAL}Bloc>()..add(const ${FLUT_FEATURE_PASCAL}Load())"
    bl_retry="context.read<${FLUT_FEATURE_PASCAL}Bloc>().add(const ${FLUT_FEATURE_PASCAL}Refresh())"
  else
    bl_type="${FLUT_FEATURE_PASCAL}Cubit"
    bl_import="${FLUT_FEATURE}_cubit.dart"
    bl_provide="create: (_) => sl<${FLUT_FEATURE_PASCAL}Cubit>()..load()"
    bl_retry="context.read<${FLUT_FEATURE_PASCAL}Cubit>().load()"
  fi
}

arch_generate_screen() {
  local bl_type bl_provide bl_import bl_retry
  _clean_feature_bl_vars
  mkf_tpl "$FLUT_BASE/presentation/screens/${FLUT_NAME}_screen.dart" "generate/screen.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL" Pascal="$FLUT_PASCAL" blImport="$bl_import" blProvide="$bl_provide" blRetry="$bl_retry" blType="$bl_type" name="$FLUT_NAME"
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

arch_generate_cubit() {
  _clean_ensure_feature_usecase
  _clean_ensure_feature_state
  mkf_tpl "$FLUT_BASE/presentation/bloc/${FLUT_NAME}_cubit.dart" "generate/cubit.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
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
  _clean_ensure_feature_usecase
  _clean_ensure_feature_state
  mkf_tpl "$FLUT_BASE/presentation/bloc/${FLUT_NAME}_event.dart" "generate/event.dart" Pascal="$FLUT_PASCAL"
  mkf_tpl "$FLUT_BASE/presentation/bloc/${FLUT_NAME}_bloc.dart" "generate/bloc.dart" Feature="$FLUT_FEATURE" FeaturePascal="$FLUT_FEATURE_PASCAL" Pascal="$FLUT_PASCAL" name="$FLUT_NAME"
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

# ── check ────────────────────────────────────────────────────────────────────
# Extra rules enforcing the dependency rule: presentation -> domain <- data.
# _check_pass/_check_err/_check_warn are defined by cmd_check before this runs.

_clean_check_entity_purity() {
  local files=() f rel err=0
  while IFS= read -r -d '' f; do files+=("$f"); done \
    < <(find lib/features -path '*/domain/entities/*.dart' -print0 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No domain entities found — skipping entity purity check."
    return
  fi

  for f in "${files[@]}"; do
    rel="${f#lib/}"
    if grep -qE "^[[:space:]]*import[[:space:]]+'package:(flutter|dio)/" "$f" 2>/dev/null; then
      _check_err "$rel — entity imports Flutter or Dio; the domain layer must stay pure"
      err=$((err + 1))
    elif grep -qE 'fromJson|toJson' "$f" 2>/dev/null; then
      _check_err "$rel — entity handles JSON; keep serialization in the data model"
      err=$((err + 1))
    fi
  done

  if [[ $err -eq 0 ]]; then
    _check_pass "Domain entities are pure (${#files[@]} entities)"
  fi
}

_clean_check_domain_isolation() {
  local files=() f rel err=0
  while IFS= read -r -d '' f; do files+=("$f"); done \
    < <(find lib/features -path '*/domain/*' -name '*.dart' -print0 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No domain layer found — skipping domain isolation check."
    return
  fi

  for f in "${files[@]}"; do
    rel="${f#lib/}"
    if grep -qE "^[[:space:]]*import[[:space:]]+'[^']*data/" "$f" 2>/dev/null; then
      _check_err "$rel — domain imports the data layer; dependencies must point inwards"
      err=$((err + 1))
    fi
  done

  if [[ $err -eq 0 ]]; then
    _check_pass "Domain layer isolated (${#files[@]} files)"
  fi
}

_clean_check_usecase_dependencies() {
  local files=() f rel err=0
  while IFS= read -r -d '' f; do files+=("$f"); done \
    < <(find lib/features -path '*/domain/usecases/*.dart' -print0 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No use cases found — skipping use case dependency check."
    return
  fi

  for f in "${files[@]}"; do
    rel="${f#lib/}"
    if grep -qE '_repository_impl\.dart|RepositoryImpl' "$f" 2>/dev/null; then
      _check_err "$rel — use case depends on a concrete repository; depend on the interface"
      err=$((err + 1))
    fi
  done

  if [[ $err -eq 0 ]]; then
    _check_pass "Use cases depend on interfaces (${#files[@]} use cases)"
  fi
}

_clean_check_repository_contracts() {
  local files=() f rel err=0
  while IFS= read -r -d '' f; do files+=("$f"); done \
    < <(find lib/features -path '*/data/repositories/*_repository_impl.dart' -print0 2>/dev/null)

  if [[ ${#files[@]} -eq 0 ]]; then
    log_info "No repository implementations found — skipping contract check."
    return
  fi

  for f in "${files[@]}"; do
    rel="${f#lib/}"
    if ! grep -qE 'implements[[:space:]]+[A-Za-z0-9_]*Repository\b' "$f" 2>/dev/null; then
      _check_warn "$rel — does not implement a domain repository interface"
      err=$((err + 1))
    fi
  done

  if [[ $err -eq 0 ]]; then
    _check_pass "Repository implementations honour their contracts (${#files[@]})"
  fi
}

arch_check_extra() {
  _clean_check_entity_purity
  _clean_check_domain_isolation
  _clean_check_usecase_dependencies
  _clean_check_repository_contracts
}
