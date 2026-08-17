# =============================================================================
#  Clean Architecture manifest
#
#  Extends ntech: the core scaffold (api client, DI, router, theme, storage,
#  error handling) is shared, so only the feature-slice layout and the extra
#  domain plumbing are defined here.
# =============================================================================

# Every value here is consumed by flut.sh and the command modules.
# shellcheck disable=SC2034

ARCH_NAME="clean"
ARCH_DESCRIPTION="Clean Architecture: domain, data, presentation per feature"
ARCH_EXTENDS="ntech"

# Same dependency set as ntech — errors are modelled with AppFailure rather
# than an Either type, so no extra functional-programming package is needed.

# A feature is a vertical slice through the three layers
FEATURE_DIRS=(domain/entities domain/repositories domain/usecases data/datasources data/models data/repositories presentation/bloc presentation/router presentation/screens presentation/widgets)

# Clean adds a base UseCase contract on top of the inherited core scaffold
REQUIRED_DIRS+=(lib/core/usecase)
REQUIRED_FILES+=(lib/core/usecase/usecase.dart)
