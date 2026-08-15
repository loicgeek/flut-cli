# =============================================================================
#  NTECH-SERVICES architecture manifest (default)
#
#  This manifest is sourced by flut.sh to describe the profile: metadata,
#  package lists, scaffold layout, and check/doctor rules.
# =============================================================================

# Every value here is consumed by flut.sh and the command modules.
# shellcheck disable=SC2034

ARCH_NAME="ntech"
ARCH_DESCRIPTION="Features-first: core, shared, features (default)"

# Packages added by `flut init` and required by `flut doctor`
RUNTIME_PACKAGES=(flutter_bloc equatable get_it auto_route dio connectivity_plus pretty_dio_logger flutter_secure_storage easy_localization logger intl)
DEV_PACKAGES=(build_runner auto_route_generator)

# Package names flagged by `flut check`
BANNED_PACKAGES=(freezed json_serializable)

# Classes the scaffold registers in GetIt that come from packages rather than
# from lib/, so `flut check` does not report them as missing
DI_EXTERNAL_CLASSES=(Dio Connectivity FlutterSecureStorage)

# Required dirs inside each feature (checked by `flut check`)
FEATURE_DIRS=(business_logic data data/models data/repositories presentation presentation/screens presentation/router presentation/widgets)

# Scaffold layout enforced by `flut doctor`
REQUIRED_DIRS=(lib/core/config lib/core/api/interceptors lib/core/auth lib/core/storage lib/core/error lib/core/bloc lib/core/theme lib/core/di lib/core/router lib/features lib/shared/models lib/shared/widgets lib/shared/utils assets/translations)
REQUIRED_FILES=(lib/main.dart lib/main_dev.dart lib/main_staging.dart lib/main_prod.dart lib/app.dart lib/core/bootstrap.dart lib/core/config/app_config.dart lib/core/di/service_locator.dart lib/core/router/app_router.dart lib/core/api/api_client.dart lib/core/api/api_endpoints.dart lib/core/api/interceptors/auth_interceptor.dart lib/core/api/interceptors/retry_interceptor.dart lib/core/api/interceptors/connectivity_interceptor.dart lib/core/storage/secure_storage.dart lib/core/error/failures.dart lib/core/error/exception_mapper.dart lib/core/auth/auth_guard.dart lib/core/bloc/app_bloc_observer.dart lib/core/theme/app_theme.dart lib/core/custom_transition_builders.dart lib/shared/widgets/loading_shimmer.dart lib/shared/widgets/empty_state.dart lib/shared/widgets/error_state.dart)
