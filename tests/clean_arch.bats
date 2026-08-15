#!/usr/bin/env bats
# =============================================================================
#  Tests for the Clean Architecture profile
#
#  These do not run `flut init` (that shells out to `flutter pub add`); the
#  profile is selected by writing flut.json directly, which is what
#  `flut init --architecture clean` and `flut architecture --set clean` do.
# =============================================================================

load helpers

setup() {
  setup_sandbox
  use_clean
}

teardown() {
  teardown_sandbox
}

use_clean() {
  printf '{\n  "architecture": "clean"\n}\n' > "$SANDBOX_DIR/flut.json"
}

use_ntech() {
  printf '{\n  "architecture": "ntech"\n}\n' > "$SANDBOX_DIR/flut.json"
}

# ── Profile registration ─────────────────────────────────────────────────────

@test "flut architecture lists clean" {
  run bash "$FLUT_SCRIPT" architecture
  [ "$status" -eq 0 ]
  [[ "$output" == *"clean"* ]]
}

@test "flut architecture --set clean updates flut.json" {
  use_ntech
  run bash "$FLUT_SCRIPT" architecture --set clean
  [ "$status" -eq 0 ]
  assert_file_contains "flut.json" '"architecture": "clean"'
}

@test "clean is reported as current when flut.json selects it" {
  run bash "$FLUT_SCRIPT" architecture
  [ "$status" -eq 0 ]
  [[ "$output" == *"* clean"* ]]
}

# ── Feature slice layout ─────────────────────────────────────────────────────

@test "clean feature creates the three layers" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]

  assert_dir_exists "lib/features/product/domain/entities"
  assert_dir_exists "lib/features/product/domain/repositories"
  assert_dir_exists "lib/features/product/domain/usecases"
  assert_dir_exists "lib/features/product/data/datasources"
  assert_dir_exists "lib/features/product/data/models"
  assert_dir_exists "lib/features/product/data/repositories"
  assert_dir_exists "lib/features/product/presentation/bloc"
  assert_dir_exists "lib/features/product/presentation/router"
  assert_dir_exists "lib/features/product/presentation/screens"
  assert_dir_exists "lib/features/product/presentation/widgets"
}

@test "clean feature does not create the ntech business_logic layout" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_dir_not_exists "lib/features/product/business_logic"
}

@test "clean feature creates one file per layer responsibility" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]

  assert_file_exists "lib/features/product/domain/entities/product.dart"
  assert_file_exists "lib/features/product/domain/repositories/product_repository.dart"
  assert_file_exists "lib/features/product/domain/usecases/product_usecase.dart"
  assert_file_exists "lib/features/product/data/models/product_model.dart"
  assert_file_exists "lib/features/product/data/datasources/product_remote_datasource.dart"
  assert_file_exists "lib/features/product/data/repositories/product_repository_impl.dart"
  assert_file_exists "lib/features/product/presentation/bloc/product_state.dart"
  assert_file_exists "lib/features/product/presentation/bloc/product_cubit.dart"
  assert_file_exists "lib/features/product/presentation/screens/product_screen.dart"
  assert_file_exists "lib/features/product/presentation/router/product_router_module.dart"
}

@test "clean feature --bloc creates event and bloc instead of cubit" {
  run bash "$FLUT_SCRIPT" feature order --bloc
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/order/presentation/bloc/order_event.dart"
  assert_file_exists "lib/features/order/presentation/bloc/order_bloc.dart"
  assert_file_not_exists "lib/features/order/presentation/bloc/order_cubit.dart"
}

@test "clean feature --service warns that it has no effect" {
  run bash "$FLUT_SCRIPT" feature product --service
  [ "$status" -eq 0 ]
  [[ "$output" == *"--service has no effect"* ]]
  assert_dir_not_exists "lib/features/product/data/services"
}

# ── Dependency rule: dependencies point inwards ──────────────────────────────

@test "clean entity has no Dio, Flutter or JSON dependency" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_not_contains "lib/features/product/domain/entities/product.dart" "package:dio"
  assert_file_not_contains "lib/features/product/domain/entities/product.dart" "package:flutter"
  assert_file_not_contains "lib/features/product/domain/entities/product.dart" "fromJson"
}

@test "clean domain repository is an interface" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/domain/repositories/product_repository.dart" "abstract interface class ProductRepository"
  assert_file_not_contains "lib/features/product/domain/repositories/product_repository.dart" "package:dio"
}

@test "clean use case depends on the repository interface, not the implementation" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/domain/usecases/product_usecase.dart" "import '../repositories/product_repository.dart'"
  assert_file_not_contains "lib/features/product/domain/usecases/product_usecase.dart" "repository_impl"
}

@test "clean repository implementation implements the domain contract" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/data/repositories/product_repository_impl.dart" "implements ProductRepository"
}

@test "clean presentation depends on the use case, not on data" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/presentation/bloc/product_cubit.dart" "domain/usecases/product_usecase.dart"
  assert_file_not_contains "lib/features/product/presentation/bloc/product_cubit.dart" "data/"
}

@test "clean model extends the entity" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/data/models/product_model.dart" "class ProductModel extends Product"
}

@test "clean state carries entities rather than models" {
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/product/presentation/bloc/product_state.dart" "List<Product> items"
  assert_file_not_contains "lib/features/product/presentation/bloc/product_state.dart" "ProductModel"
}

# ── generate ─────────────────────────────────────────────────────────────────

@test "clean exposes entity, usecase and datasource generate types" {
  run bash "$FLUT_SCRIPT" generate
  [ "$status" -eq 1 ]
  [[ "$output" == *"entity"* ]]
  [[ "$output" == *"usecase"* ]]
  [[ "$output" == *"datasource"* ]]
}

@test "clean generate entity creates the entity" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate entity product category
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/domain/entities/category.dart"
  assert_file_contains "lib/features/product/domain/entities/category.dart" "class Category"
}

@test "clean generate usecase also creates its missing dependencies" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate usecase product category
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/domain/entities/category.dart"
  assert_file_exists "lib/features/product/domain/repositories/category_repository.dart"
  assert_file_exists "lib/features/product/domain/usecases/category_usecase.dart"
}

@test "clean generate datasource also creates the model and entity" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate datasource product category
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/data/datasources/category_remote_datasource.dart"
  assert_file_exists "lib/features/product/data/models/category_model.dart"
  assert_file_exists "lib/features/product/domain/entities/category.dart"
}

@test "clean generate repository creates both interface and implementation" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate repository product category
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/domain/repositories/category_repository.dart"
  assert_file_exists "lib/features/product/data/repositories/category_repository_impl.dart"
}

@test "clean generate cubit binds to the feature state" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate cubit product listing
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/presentation/bloc/listing_cubit.dart"
  assert_file_contains "lib/features/product/presentation/bloc/listing_cubit.dart" "Cubit<ProductState>"
}

@test "clean generate cubit creates the feature state when missing" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  rm "$SANDBOX_DIR/lib/features/product/presentation/bloc/product_state.dart"
  run bash "$FLUT_SCRIPT" generate cubit product listing
  [ "$status" -eq 0 ]
  assert_file_exists "lib/features/product/presentation/bloc/product_state.dart"
}

# ── Isolation from ntech ─────────────────────────────────────────────────────

@test "ntech does not accept the clean-only generate types" {
  use_ntech
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate entity product category
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown type"* ]]
}

@test "ntech still scaffolds its own layout when clean is installed" {
  use_ntech
  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_dir_exists "lib/features/product/business_logic"
  assert_dir_not_exists "lib/features/product/domain"
}

# ── check ────────────────────────────────────────────────────────────────────

@test "flut check accepts a clean feature structure" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" check
  [[ "$output" == *"Feature structure"* ]]
  [[ "$output" != *"missing required dir"* ]]
}

# ── Architecture-aware check rules ───────────────────────────────────────────

@test "clean check reports the domain rules on a valid feature" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" check
  [[ "$output" == *"Domain entities are pure"* ]]
  [[ "$output" == *"Domain layer isolated"* ]]
  [[ "$output" == *"Use cases depend on interfaces"* ]]
  [[ "$output" == *"Repository implementations honour their contracts"* ]]
}

@test "ntech check does not run the clean domain rules" {
  use_ntech
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" check
  [[ "$output" != *"Domain entities are pure"* ]]
  [[ "$output" != *"Use cases depend on interfaces"* ]]
}

@test "clean check catches an entity importing Flutter" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  sed -i "1i import 'package:flutter/material.dart';" \
    "$SANDBOX_DIR/lib/features/product/domain/entities/product.dart"

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"entity imports Flutter or Dio"* ]]
}

@test "clean check catches an entity doing JSON" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  echo "// fromJson belongs in the model" \
    >> "$SANDBOX_DIR/lib/features/product/domain/entities/product.dart"

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"keep serialization in the data model"* ]]
}

@test "clean check catches the domain importing the data layer" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  sed -i "1i import '../../data/models/product_model.dart';" \
    "$SANDBOX_DIR/lib/features/product/domain/repositories/product_repository.dart"

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"domain imports the data layer"* ]]
}

@test "clean check catches a use case depending on a concrete repository" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  sed -i "s/class ProductUseCase/\/\/ ProductRepositoryImpl\nclass ProductUseCase/" \
    "$SANDBOX_DIR/lib/features/product/domain/usecases/product_usecase.dart"

  run bash "$FLUT_SCRIPT" check
  [ "$status" -eq 2 ]
  [[ "$output" == *"depend on the interface"* ]]
}

@test "clean check warns when a repository implementation drops its contract" {
  bash "$FLUT_SCRIPT" feature product >/dev/null 2>&1
  sed -i 's/implements ProductRepository//' \
    "$SANDBOX_DIR/lib/features/product/data/repositories/product_repository_impl.dart"

  run bash "$FLUT_SCRIPT" check
  [[ "$output" == *"does not implement a domain repository interface"* ]]
}

# ── doctor is profile-aware ──────────────────────────────────────────────────

@test "doctor requires the clean use case base class" {
  mkdir -p "$SANDBOX_DIR/lib/core/usecase"
  touch "$SANDBOX_DIR/lib/core/usecase/usecase.dart"
  run bash "$FLUT_SCRIPT" doctor
  [[ "$output" == *"25 files"* ]] || [[ "$output" == *"Scaffold structure"* ]]
}

@test "doctor counts more required files for clean than for ntech" {
  run bash "$FLUT_SCRIPT" doctor
  local clean_out="$output"
  use_ntech
  run bash "$FLUT_SCRIPT" doctor
  [[ "$clean_out" != "$output" ]]
}

# ── Generated clean code must reference only things that exist ───────────────

@test "clean generate screen binds to the feature's bloc when it uses one" {
  bash "$FLUT_SCRIPT" feature order --bloc >/dev/null 2>&1
  run bash "$FLUT_SCRIPT" generate screen order summary
  [ "$status" -eq 0 ]
  assert_file_contains "lib/features/order/presentation/screens/summary_screen.dart" "order_bloc.dart"
  assert_file_not_contains "lib/features/order/presentation/screens/summary_screen.dart" "order_cubit.dart"
}

@test "clean bloc re-exports its events so screens can use them" {
  bash "$FLUT_SCRIPT" feature order --bloc >/dev/null 2>&1
  assert_file_contains "lib/features/order/presentation/bloc/order_bloc.dart" "export 'order_event.dart';"
}

@test "clean feature registers its endpoint" {
  mkdir -p "$SANDBOX_DIR/lib/core/api"
  printf 'abstract final class ApiEndpoints {\n  // Add endpoints by domain below\n}\n' \
    > "$SANDBOX_DIR/lib/core/api/api_endpoints.dart"

  run bash "$FLUT_SCRIPT" feature product
  [ "$status" -eq 0 ]
  assert_file_contains "lib/core/api/api_endpoints.dart" "static const products = '/products';"
}
