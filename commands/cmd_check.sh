# ==============================================================================
#  COMMAND: check — Architecture Audit
# ==============================================================================

cmd_check() {
  local warnings=0
  local errors=0

  # ── helpers for internal check functions ────────────────────────────────────
  # Note: use $((var + 1)) instead of var=$((var + 1)) because with set -e,
  # errors=$((errors + 1)) exits the script when errors is 0 (returns old value 0 = falsy).
  _check_pass() { log_success "$1"; }
  _check_err()  { errors=$((errors + 1)); log_error "$1"; }
  _check_warn() { warnings=$((warnings + 1)); log_warning "$1"; }

  # ── Check 1: Feature structure ─────────────────────────────────────────────
  _check_1_feature_structure() {
    local features=()
    for f in lib/features/*/; do
      [[ -d "$f" ]] || continue
      features+=("$(basename "$f")")
    done

    if [[ ${#features[@]} -eq 0 ]]; then
      log_info "No features found — skipping feature structure check."
      return 0
    fi

    local total_err=0
    for feat in "${features[@]}"; do
      local missing=()
      [[ -d "lib/features/$feat/business_logic"       ]] || missing+=("business_logic")
      [[ -d "lib/features/$feat/data"                 ]] || missing+=("data")
      [[ -d "lib/features/$feat/data/models"          ]] || missing+=("data/models")
      [[ -d "lib/features/$feat/data/repositories"    ]] || missing+=("data/repositories")
      [[ -d "lib/features/$feat/presentation"         ]] || missing+=("presentation")
      [[ -d "lib/features/$feat/presentation/screens" ]] || missing+=("presentation/screens")
      [[ -d "lib/features/$feat/presentation/router"  ]] || missing+=("presentation/router")
      [[ -d "lib/features/$feat/presentation/widgets" ]] || missing+=("presentation/widgets")

      if [[ ${#missing[@]} -gt 0 ]]; then
        _check_err "$feat — missing required dir(s): ${missing[*]}"
        total_err=$((total_err + 1))
      fi
    done

    if [[ $total_err -eq 0 ]]; then
      _check_pass "Feature structure (${#features[@]} features)"
    fi
  }

  # ── Check 2: State is sealed ───────────────────────────────────────────────
  _check_2_sealed_states() {
    local files=()
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find lib/ -name '*_state.dart' -print0 2>/dev/null)

    local total=${#files[@]}
    local valid=0
    local err=0

    if [[ $total -eq 0 ]]; then
      log_info "No state files found — skipping sealed state check."
      return
    fi

    for f in "${files[@]}"; do
      if grep -q 'sealed class' "$f" 2>/dev/null; then
        valid=$((valid + 1))
      else
        _check_err "${f#lib/} — state file does not declare a sealed class"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Sealed states ($valid/$total valid)"
    fi
  }

  # ── Check 3: No banned codegen packages ────────────────────────────────────
  _check_3_banned_codegen() {
    if [[ ! -f "pubspec.yaml" ]]; then
      _check_warn "pubspec.yaml not found — cannot check for banned packages"
      return
    fi

    local err=0
    if grep -qE '^[[:space:]]*freezed[[:space:]]*$|freezed:' pubspec.yaml 2>/dev/null; then
      _check_warn "Banned package 'freezed' found in pubspec.yaml"
      err=$((err + 1))
    fi
    if grep -qE '^[[:space:]]*json_serializable[[:space:]]*$|json_serializable:' pubspec.yaml 2>/dev/null; then
      _check_warn "Banned package 'json_serializable' found in pubspec.yaml"
      err=$((err + 1))
    fi

    if [[ $err -eq 0 ]]; then
      _check_pass "No banned packages"
    fi
  }

  # ── Check 4: Layer boundaries ──────────────────────────────────────────────
  _check_4_layer_boundaries() {
    local files=()
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find lib/features/*/presentation -name '*.dart' -print0 2>/dev/null)

    if [[ ${#files[@]} -eq 0 ]]; then
      log_info "No presentation files found — skipping layer boundary check."
      return
    fi

    local err=0
    for f in "${files[@]}"; do
      local feat
      feat="${f#lib/features/}"; feat="${feat%%/*}"
      local rel="${f#lib/}"
      if grep -qE "import.*data/" "$f" 2>/dev/null; then
        _check_err "$feat — $rel imports data/ directly"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Layer boundaries — no presentation files import data/ directly"
    fi
  }

  # ── Check 5: Router registration ───────────────────────────────────────────
  _check_5_router_registration() {
    local screens=()
    while IFS= read -r -d '' f; do
      screens+=("$f")
    done < <(find lib/features -path '*/presentation/screens/*.dart' -print0 2>/dev/null)

    if [[ ${#screens[@]} -eq 0 ]]; then
      log_info "No screens found — skipping router registration check."
      return
    fi

    if [[ ! -f "lib/core/router/app_router.dart" ]]; then
      _check_warn "lib/core/router/app_router.dart not found — cannot verify router registration"
      return
    fi

    local router_content
    router_content=$(cat "lib/core/router/app_router.dart" 2>/dev/null)
    local total=${#screens[@]}
    local registered=0
    local err=0

    for f in "${screens[@]}"; do
      local basename
      basename="$(basename "$f" .dart)"
      # AutoRoute converts auth_screen -> AuthRoute (replaceInRouteName: 'Screen,Route')
      # Convert snake_case to PascalCase (reusing to_pascal) then append Route
      local name_no_suffix
      name_no_suffix=$(echo "$basename" | sed 's/_screen$//' | sed 's/_route$//')
      local pascal
      pascal="$(to_pascal "$name_no_suffix")Route"

      if echo "$router_content" | grep -q "$pascal"; then
        registered=$((registered + 1))
      else
        local rel="${f#lib/}"
        _check_warn "$rel — may not be registered in app_router.dart (seeking: $pascal)"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Router registration ($registered/$total screens)"
    fi
  }

  # ── Check 6: DI registration ───────────────────────────────────────────────
  _check_6_di_registration() {
    if [[ ! -f "lib/core/di/service_locator.dart" ]]; then
      _check_warn "lib/core/di/service_locator.dart not found — skipping DI check"
      return
    fi

    local sl_content
    sl_content=$(cat "lib/core/di/service_locator.dart" 2>/dev/null)
    local err=0
    local total=0
    local matched=0

    # Find all sl.registerSingleton<...> and sl.registerFactory<...>
    local registrations=()
    while IFS= read -r line; do
      registrations+=("$line")
    done < <(echo "$sl_content" | grep -oE 'sl\.(registerSingleton|registerFactory)<[A-Za-z0-9_]+>' || true)

    total=${#registrations[@]}

    if [[ $total -eq 0 ]]; then
      log_info "No DI registrations found — skipping DI check."
      return
    fi

    for reg in "${registrations[@]}"; do
      local class_name
      class_name=$(echo "$reg" | sed 's/.*<//; s/>.*//')
      local file
      file=$(find lib/ -name "${class_name}.dart" -print -quit 2>/dev/null)
      if [[ -n "$file" ]]; then
        matched=$((matched + 1))
      else
        _check_warn "$class_name is registered in service_locator.dart but no corresponding file found"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "DI registration ($matched/$total registrations have matching files)"
    fi
  }

  # ── Check 7: Translation keys ──────────────────────────────────────────────
  _check_7_translation_keys() {
    if [[ ! -f "assets/translations/en.json" ]]; then
      _check_warn "assets/translations/en.json not found — skipping translation key check"
      return
    fi
    if [[ ! -f "assets/translations/fr.json" ]]; then
      _check_warn "assets/translations/fr.json not found — skipping translation key check"
      return
    fi

    local en_content fr_content
    en_content=$(cat "assets/translations/en.json" 2>/dev/null)
    fr_content=$(cat "assets/translations/fr.json" 2>/dev/null)

    local err=0
    local found=0

    # Find all tr('...') or tr("...") calls in Dart files
    local tr_keys=()
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      tr_keys+=("$key")
    done < <(grep -rohE "tr\\([\"']([^\"']+)[\"'']" --include='*.dart' lib/ 2>/dev/null | sed "s/tr(\"//; s/tr('//; s/\"$//; s/'$//; s/)$//" | sort -u || true)

    if [[ ${#tr_keys[@]} -eq 0 ]]; then
      log_info "No tr() calls found — skipping translation key check."
      return
    fi

    for key in "${tr_keys[@]}"; do
      found=$((found + 1))
      local in_en=0
      local in_fr=0

      if echo "$en_content" | grep -qF "\"$key\""; then
        in_en=1
      fi
      if echo "$fr_content" | grep -qF "\"$key\""; then
        in_fr=1
      fi

      if [[ $in_en -eq 0 ]] && [[ $in_fr -eq 0 ]]; then
        _check_warn "Translation key \"$key\" missing from both en.json and fr.json"
        err=$((err + 1))
      elif [[ $in_en -eq 0 ]]; then
        _check_warn "Translation key \"$key\" missing from en.json"
        err=$((err + 1))
      elif [[ $in_fr -eq 0 ]]; then
        _check_warn "Translation key \"$key\" missing from fr.json"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Translation keys ($found keys found in both en.json and fr.json)"
    fi
  }

  # ── Check 8: No orphaned generated files ───────────────────────────────────
  _check_8_orphaned_generated() {
    local gr_files=()
    while IFS= read -r -d '' f; do
      gr_files+=("$f")
    done < <(find lib/ -name '*.gr.dart' -print0 2>/dev/null)

    if [[ ${#gr_files[@]} -eq 0 ]]; then
      log_info "No .gr.dart files found — skipping orphaned generated file check."
      return
    fi

    local err=0
    for f in "${gr_files[@]}"; do
      local source
      source="${f%.gr.dart}.dart"
      if [[ ! -f "$source" ]]; then
        _check_warn "${f#lib/} — generated file exists but source ${source#lib/} has been deleted"
        err=$((err + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "No orphaned generated files (${#gr_files[@]} .gr.dart files)"
    fi
  }

  # ── Check 9: Cubit/Bloc convention ─────────────────────────────────────────
  _check_9_cubit_convention() {
    local cubit_files=()
    while IFS= read -r -d '' f; do
      cubit_files+=("$f")
    done < <(find lib/ \( -name '*_cubit.dart' -o -name '*_bloc.dart' \) -print0 2>/dev/null)

    if [[ ${#cubit_files[@]} -eq 0 ]]; then
      log_info "No Cubit/Bloc files found — skipping convention check."
      return
    fi

    local err=0
    local total=0
    local clean=0

    for f in "${cubit_files[@]}"; do
      total=$((total + 1))
      local content
      content=$(cat "$f" 2>/dev/null)
      # Check if file uses try/catch
      if echo "$content" | grep -qE 'catch\s*\('; then
        local rel="${f#lib/}"
        # Check if it catches AppFailure or generic Exception
        if echo "$content" | grep -q 'catch.*AppFailure' || echo "$content" | grep -q 'on AppFailure'; then
          clean=$((clean + 1))
        elif echo "$content" | grep -qE 'catch\s*\(\s*e\s*\)|catch\s*\(\s*_\s*\)'; then
          # A bare catch — might be catching generic Exception
          # Check if it's using AppFailure inside
          if echo "$content" | grep -q 'AppFailure'; then
            clean=$((clean + 1))
          else
            _check_err "$rel — uses generic Exception catch instead of AppFailure"
            err=$((err + 1))
          fi
        else
          clean=$((clean + 1))
        fi
      else
        clean=$((clean + 1))
      fi
    done

    if [[ $err -eq 0 ]]; then
      _check_pass "Cubit/Bloc convention ($clean/$total use AppFailure correctly)"
    fi
  }

  # ── Run all checks ─────────────────────────────────────────────────────────
  log_section "Architecture Audit"

  echo ""
  _check_1_feature_structure
  _check_2_sealed_states
  _check_3_banned_codegen
  _check_4_layer_boundaries
  _check_5_router_registration
  _check_6_di_registration
  _check_7_translation_keys
  _check_8_orphaned_generated
  _check_9_cubit_convention

  # ── Summary ────────────────────────────────────────────────────────────────
  echo ""
  if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    log_success "All checks passed — clean architecture!"
  elif [[ $errors -eq 0 ]]; then
    echo -e "  ${YELLOW}$warnings warning(s)${RESET} — see details above"
  else
    echo -e "  ${YELLOW}$warnings warning(s), ${RED}$errors error(s)${RESET} — see details above"
  fi
  echo ""

  # Exit codes: 0=all clear, 1=warnings only, 2=errors found
  if [[ $errors -gt 0 ]]; then
    exit 2
  elif [[ $warnings -gt 0 ]]; then
    exit 1
  fi
}
