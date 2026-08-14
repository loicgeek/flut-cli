# ==============================================================================
#  COMMAND: init
# ==============================================================================
cmd_init() {
  local architecture="$FLUT_DEFAULT_ARCH"
  local arch_explicit=false

  # Parse flags (command name already shifted by the dispatcher)
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --architecture|-a)
        architecture="${2:-}"
        if [[ -z "$architecture" ]]; then
          log_error "Missing value for --architecture"
          usage
          exit 1
        fi
        arch_explicit=true
        shift 2 ;;
      --architecture=*)
        architecture="${1#*=}"
        arch_explicit=true
        shift ;;
      *) log_error "Unknown flag: $1"; usage; exit 1 ;;
    esac
  done

  log_section "Initializing Flutter scaffold"

  if [[ ! -f "pubspec.yaml" ]]; then
    log_error "pubspec.yaml not found. Run from project root."
    exit 1
  fi

  # Re-inits keep the project's existing architecture unless one was given
  if [[ "$arch_explicit" == false && -f "$FLUT_CONFIG_FILE" ]]; then
    architecture="$(_arch_current)"
  fi

  if ! _arch_exists "$architecture"; then
    log_error "Unknown architecture: $architecture"
    echo "  Installed: $(_arch_list)"
    exit 1
  fi

  local L="lib"

  log_section "Architecture"
  log_info "profile: $architecture"
  _arch_write "$architecture"

  log_section "Directories"
  mkd "$L/core/config"
  mkd "$L/core/api/interceptors"
  mkd "$L/core/auth"
  mkd "$L/core/storage"
  mkd "$L/core/error"
  mkd "$L/core/bloc"
  mkd "$L/core/theme"
  mkd "$L/core/di"
  mkd "$L/core/router"
  mkd "$L/features"
  mkd "$L/shared/models"
  mkd "$L/shared/widgets"
  mkd "$L/shared/utils"
  mkd "assets/translations"
  mkd "assets/images"
  mkd "assets/icons"
  mkd "assets/lottie"

  log_section "Files"

  # --------------------------------------------------------------------------
  # Entry points
  # --------------------------------------------------------------------------
  # main.dart  →  default entry point for `flutter run` (dev flavor)
  # main_dev / main_staging / main_prod  →  explicit flavor targets for CI
  mkf_tpl "$L/main.dart" "init/main.dart"

  mkf_tpl "$L/main_dev.dart" "init/main_dev.dart"

  mkf_tpl "$L/main_staging.dart" "init/main_staging.dart"

  mkf_tpl "$L/main_prod.dart" "init/main_prod.dart"

  # --------------------------------------------------------------------------
  # app.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/app.dart" "init/app.dart"

  # --------------------------------------------------------------------------
  # core/config/app_config.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/config/app_config.dart" "init/core/config/app_config.dart"

  # --------------------------------------------------------------------------
  # core/bootstrap.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/bootstrap.dart" "init/core/bootstrap.dart"

  # --------------------------------------------------------------------------
  # core/custom_transition_builders.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/custom_transition_builders.dart" "init/core/custom_transition_builders.dart"

  # --------------------------------------------------------------------------
  # core/di/service_locator.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/di/service_locator.dart" "init/core/di/service_locator.dart"

  # --------------------------------------------------------------------------
  # core/router/app_router.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/router/app_router.dart" "init/core/router/app_router.dart"

  # --------------------------------------------------------------------------
  # core/api/api_client.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/api/api_client.dart" "init/core/api/api_client.dart"

  # --------------------------------------------------------------------------
  # core/api/api_endpoints.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/api/api_endpoints.dart" "init/core/api/api_endpoints.dart"

  # --------------------------------------------------------------------------
  # core/api/interceptors
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/api/interceptors/auth_interceptor.dart" "init/core/api/interceptors/auth_interceptor.dart"

  mkf_tpl "$L/core/api/interceptors/retry_interceptor.dart" "init/core/api/interceptors/retry_interceptor.dart"

  mkf_tpl "$L/core/api/interceptors/connectivity_interceptor.dart" "init/core/api/interceptors/connectivity_interceptor.dart"

  # --------------------------------------------------------------------------
  # core/storage/secure_storage.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/storage/secure_storage.dart" "init/core/storage/secure_storage.dart"

  # --------------------------------------------------------------------------
  # core/error
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/error/failures.dart" "init/core/error/failures.dart"

  mkf_tpl "$L/core/error/exception_mapper.dart" "init/core/error/exception_mapper.dart"

  # --------------------------------------------------------------------------
  # core/auth/auth_guard.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/auth/auth_guard.dart" "init/core/auth/auth_guard.dart"

  # --------------------------------------------------------------------------
  # core/bloc/app_bloc_observer.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/bloc/app_bloc_observer.dart" "init/core/bloc/app_bloc_observer.dart"

  # --------------------------------------------------------------------------
  # core/theme/app_theme.dart
  # --------------------------------------------------------------------------
  mkf_tpl "$L/core/theme/app_theme.dart" "init/core/theme/app_theme.dart"

  # --------------------------------------------------------------------------
  # shared/widgets
  # --------------------------------------------------------------------------
  mkf_tpl "$L/shared/widgets/loading_shimmer.dart" "init/shared/widgets/loading_shimmer.dart"

  mkf_tpl "$L/shared/widgets/empty_state.dart" "init/shared/widgets/empty_state.dart"

  mkf_tpl "$L/shared/widgets/error_state.dart" "init/shared/widgets/error_state.dart"

  # --------------------------------------------------------------------------
  # Translations
  # --------------------------------------------------------------------------
  mkf_tpl "assets/translations/fr.json" "init/translations/fr.json"

  mkf_tpl "assets/translations/en.json" "init/translations/en.json"

  # --------------------------------------------------------------------------
  # IDE — VS Code launch configurations
  # --------------------------------------------------------------------------
  log_section "IDE settings"

  mkd ".vscode"
  mkf_tpl ".vscode/launch.json" "init/vscode/launch.json"

  # --------------------------------------------------------------------------
  # IDE — Android Studio / IntelliJ run configurations
  # --------------------------------------------------------------------------
  mkd ".idea/runConfigurations"

  # shellcheck disable=SC2016  # $PROJECT_DIR$ is an IntelliJ variable, not bash
  mkf_tpl ".idea/runConfigurations/Dev.xml" "init/idea/Dev.xml"

  # shellcheck disable=SC2016
  mkf_tpl ".idea/runConfigurations/Dev_profile.xml" "init/idea/Dev_profile.xml"

  # shellcheck disable=SC2016
  mkf_tpl ".idea/runConfigurations/Staging.xml" "init/idea/Staging.xml"

  # shellcheck disable=SC2016
  mkf_tpl ".idea/runConfigurations/Prod.xml" "init/idea/Prod.xml"

  # --------------------------------------------------------------------------
  # flutter pub add
  # --------------------------------------------------------------------------
  log_section "Installing packages"

  if ! command -v flutter &>/dev/null; then
    log_warning "flutter not found in PATH - skipping pub add."
    log_warning "Run manually:"
    _print_pub_cmds
    _print_success
    return
  fi

  _manifest_env

  log_info "Adding runtime packages..."
  flutter pub add "${RUNTIME_PACKAGES[@]}" || { log_error "pub add failed."; exit 1; }
  log_success "Runtime packages added."

  log_info "Adding dev packages..."
  flutter pub add --dev "${DEV_PACKAGES[@]}" || { log_error "pub add --dev failed."; exit 1; }
  log_success "Dev packages added."

  _print_success
}

_print_pub_cmds() {
  echo ""
  echo "  flutter pub add \\"
  local line=""
  for pkg in "${RUNTIME_PACKAGES[@]}"; do
    if [[ -z "$line" ]]; then
      line="    $pkg"
    elif [[ ${#line} -ge 68 ]]; then
      echo "$line \\"
      line="    $pkg"
    else
      line="$line $pkg"
    fi
  done
  echo "$line"
  echo ""
  echo "  flutter pub add --dev ${DEV_PACKAGES[*]}"
  echo ""
}

_print_success() {
  echo ""
  echo -e "${BOLD}${GREEN}  Scaffold ready.${RESET}"
  echo ""
  echo -e "${YELLOW}  Next steps:${RESET}"
  echo "    1. dart run build_runner build --delete-conflicting-outputs"
  echo "    2. Register features in lib/core/di/service_locator.dart"
  echo "    3. flut feature <name>"
  echo ""
}
