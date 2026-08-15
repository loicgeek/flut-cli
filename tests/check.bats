#!/usr/bin/env bats
# =============================================================================
#  Tests for flut check — architecture audit command
# =============================================================================

load helpers

setup() {
  setup_sandbox
}

teardown() {
  teardown_sandbox
}

# ── Help / Usage ─────────────────────────────────────────────────────────────

@test "flut --help mentions check command" {
  run bash "$FLUT_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"check"* ]]
  [[ "$output" == *"Audit"* ]]
}

# ── Basic check with no features ─────────────────────────────────────────────

@test "flut check on empty project reports no features (warnings about missing core files)" {
  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"No features found"* ]]
  [[ "$output" == *"warning(s)"* ]]
}

# ── Check detects missing feature structure ──────────────────────────────────

@test "flut check detects missing feature directories" {
  # Create a partial feature (missing presentation/router)
  mkdir -p "lib/features/test_feature/business_logic"
  mkdir -p "lib/features/test_feature/data/models"
  mkdir -p "lib/features/test_feature/data/repositories"
  mkdir -p "lib/features/test_feature/presentation/screens"
  mkdir -p "lib/features/test_feature/presentation/widgets"
  # Deliberately missing: presentation/router

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"missing"* ]]
  [[ "$output" == *"presentation/router"* ]]
}

# ── Check validates complete feature structure ───────────────────────────────

@test "flut check passes for complete feature structure" {
  # Create a full feature using the feature command
  run bash "$FLUT_SCRIPT" feature valid_feature
  [ "$status" -eq 0 ]

  run bash "$FLUT_SCRIPT" check
  # Exit 1 because core files (router, DI, translations) are missing
  [ "$status" -eq 1 ]
  [[ "$output" == *"Feature structure"* ]]
  [[ "$output" == *"warning(s)"* ]]
}

# ── Check validates sealed states ────────────────────────────────────────────

@test "flut check validates sealed state classes" {
  run bash "$FLUT_SCRIPT" feature test_feat
  [ "$status" -eq 0 ]

  # Write a non-sealed state file (should fail)
  mkdir -p "lib/features/bad_feat/business_logic"
  cat > "lib/features/bad_feat/business_logic/bad_feat_state.dart" <<'EOF'
class BadFeatState { const BadFeatState(); }
final class BadFeatInitial extends BadFeatState { const BadFeatInitial(); }
EOF

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"not declare a sealed class"* ]]
}

# ── Check detects banned packages ────────────────────────────────────────────

@test "flut check warns about banned freezed package" {
  run bash "$FLUT_SCRIPT" feature test_feat
  [ "$status" -eq 0 ]

  echo "  freezed:" >> "pubspec.yaml"

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"Banned package"* ]]
  [[ "$output" == *"freezed"* ]]
}

# ── Check detects layer boundary violations ──────────────────────────────────

@test "flut check detects layer boundary violations" {
  run bash "$FLUT_SCRIPT" feature boundary_test
  [ "$status" -eq 0 ]

  # Add a direct import from presentation to data
  cat >> "lib/features/boundary_test/presentation/screens/boundary_test_screen.dart" <<'EOF'
import '../../data/models/boundary_test_model.dart';
EOF

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"imports data/ directly"* ]]
}

# ── Check detects translation key issues ─────────────────────────────────────

@test "flut check warns about missing translation keys" {
  run bash "$FLUT_SCRIPT" feature trans_test
  [ "$status" -eq 0 ]

  # Create translation files so the check doesn't skip
  mkdir -p "assets/translations"
  cat > "assets/translations/en.json" <<'EOF'
{
  "common": {
    "loading": "Loading..."
  }
}
EOF
  cat > "assets/translations/fr.json" <<'EOF'
{
  "common": {
    "loading": "Chargement..."
  }
}
EOF

  # Create a .dart file with a tr() call referencing a missing key
  mkdir -p "lib/features/trans_test/presentation/screens"
  cat > "lib/features/trans_test/presentation/screens/trans_test_screen.dart" <<'EOF'
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TransTestScreen extends StatelessWidget {
  const TransTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(tr('trans_test.title'));
  }
}
EOF

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"Translation key"* ]]
  [[ "$output" == *"trans_test.title"* ]]
}

# ── Check exits 0 for clean project ──────────────────────────────────────────

@test "flut check on a full scaffolded project shows audit results" {
  # Init the full scaffold (this creates core files + translations)
  run bash "$FLUT_SCRIPT" init
  [ "$status" -eq 0 ]

  # Add a feature
  run bash "$FLUT_SCRIPT" feature audit_ok
  [ "$status" -eq 0 ]

  run bash "$FLUT_SCRIPT" check
  # Should have warnings about translation keys (screen tr() keys not in JSON yet)
  [[ "$output" == *"Translation key"* ]] || [[ "$output" == *"Feature structure"* ]]
}

# ── False positives that made a pristine scaffold fail its own audit ─────────

@test "flut check does not treat shared widgets as bloc state files" {
  mkdir -p "$SANDBOX_DIR/lib/shared/widgets"
  cat > "$SANDBOX_DIR/lib/shared/widgets/empty_state.dart" <<'DART'
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
DART

  run bash "$FLUT_SCRIPT" check
  [[ "$output" != *"empty_state.dart — state file does not declare a sealed class"* ]]
}

@test "flut check matches DI registrations against snake_case files" {
  mkdir -p "$SANDBOX_DIR/lib/core/di" "$SANDBOX_DIR/lib/core/config"
  cat > "$SANDBOX_DIR/lib/core/config/app_config.dart" <<'DART'
class AppConfig {
  const AppConfig();
}
DART
  cat > "$SANDBOX_DIR/lib/core/di/service_locator.dart" <<'DART'
void setup() {
  sl.registerSingleton<AppConfig>(config);
}
DART

  run bash "$FLUT_SCRIPT" check
  [[ "$output" != *"AppConfig is registered"* ]]
}

@test "flut check ignores commented-out DI registrations" {
  mkdir -p "$SANDBOX_DIR/lib/core/di"
  cat > "$SANDBOX_DIR/lib/core/di/service_locator.dart" <<'DART'
void setup() {
  // sl.registerSingleton<AuthRepository>(AuthRepository(sl()));
  // sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));
}
DART

  run bash "$FLUT_SCRIPT" check
  [[ "$output" != *"AuthRepository is registered"* ]]
  [[ "$output" != *"AuthCubit is registered"* ]]
}

@test "flut check does not flag package classes registered in DI" {
  mkdir -p "$SANDBOX_DIR/lib/core/di"
  cat > "$SANDBOX_DIR/lib/core/di/service_locator.dart" <<'DART'
void setup() {
  sl.registerSingleton<Dio>(buildDioClient());
}
DART

  run bash "$FLUT_SCRIPT" check
  [[ "$output" != *"Dio is registered"* ]]
}

@test "flut check still reports a DI registration with no class anywhere" {
  mkdir -p "$SANDBOX_DIR/lib/core/di"
  cat > "$SANDBOX_DIR/lib/core/di/service_locator.dart" <<'DART'
void setup() {
  sl.registerSingleton<GhostRepository>(GhostRepository(sl()));
}
DART

  run bash "$FLUT_SCRIPT" check
  [[ "$output" == *"GhostRepository is registered"* ]]
}
