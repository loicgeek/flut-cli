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
  mkf "$BASE/data/models/${name}_model.dart" "class ${pascal}Model {
  const ${pascal}Model({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return ${pascal}Model(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  ${pascal}Model copyWith({
    String? id,
    // TODO: add fields
  }) {
    return ${pascal}Model(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${pascal}Model && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '${pascal}Model(id: \$id)';
}
"
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
  mkf "$BASE/presentation/screens/${name}_screen.dart" "import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/${feature}_cubit.dart';
import '../../business_logic/${feature}_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<${feature_pascal}Cubit>()..load(),
      child: const _${pascal}View(),
    );
  }
}

class _${pascal}View extends StatelessWidget {
  const _${pascal}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${name}.title'.tr())),
      body: BlocConsumer<${feature_pascal}Cubit, ${feature_pascal}State>(
        listener: (context, state) {
          if (state is ${feature_pascal}Error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          ${feature_pascal}Initial() => const SizedBox.shrink(),
          ${feature_pascal}Loading() => const Center(child: LoadingShimmer()),
          ${feature_pascal}Error()   => ErrorState(
              message: (state as ${feature_pascal}Error).message,
              onRetry: () => context.read<${feature_pascal}Cubit>().load(),
            ),
          ${feature_pascal}Loaded()  => _${pascal}List(
              items: (state as ${feature_pascal}Loaded).items,
            ),
        },
      ),
    );
  }
}

class _${pascal}List extends StatelessWidget {
  const _${pascal}List({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: '${name}.empty'.tr());
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].id)),
      // TODO: build item UI
    );
  }
}
"
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
  mkf "$BASE/data/repositories/${name}_repository.dart" "import 'package:dio/dio.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/${name}_model.dart';

class ${pascal}Repository {
  const ${pascal}Repository(this._dio);
  final Dio _dio;

  Future<List<${pascal}Model>> get${pascal}List() async {
    try {
      final response = await _dio.get(ApiEndpoints.${name}s);
      return (response.data as List)
          .map((e) => ${pascal}Model.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
"
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
    mkf "$state_file" "import '../data/models/${feature}_model.dart';

sealed class ${feature_pascal}State { const ${feature_pascal}State(); }

final class ${feature_pascal}Initial extends ${feature_pascal}State { const ${feature_pascal}Initial(); }
final class ${feature_pascal}Loading extends ${feature_pascal}State { const ${feature_pascal}Loading(); }
final class ${feature_pascal}Loaded  extends ${feature_pascal}State {
  const ${feature_pascal}Loaded(this.items);
  final List<${feature_pascal}Model> items;
}
final class ${feature_pascal}Error extends ${feature_pascal}State {
  const ${feature_pascal}Error(this.message);
  final String message;
}
"
  fi

  mkf "$BASE/business_logic/${name}_cubit.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${feature}_state.dart';

class ${pascal}Cubit extends Cubit<${feature_pascal}State> {
  ${pascal}Cubit(this._repository) : super(const ${feature_pascal}Initial());
  final ${pascal}Repository _repository;

  Future<void> load() async {
    emit(const ${feature_pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      if (!isClosed) emit(${feature_pascal}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(${feature_pascal}Error(f.userMessage));
    }
  }
}
"
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
    mkf "$state_file" "import '../data/models/${feature}_model.dart';

sealed class ${feature_pascal}State { const ${feature_pascal}State(); }

final class ${feature_pascal}Initial extends ${feature_pascal}State { const ${feature_pascal}Initial(); }
final class ${feature_pascal}Loading extends ${feature_pascal}State { const ${feature_pascal}Loading(); }
final class ${feature_pascal}Loaded  extends ${feature_pascal}State {
  const ${feature_pascal}Loaded(this.items);
  final List<${feature_pascal}Model> items;
}
final class ${feature_pascal}Error extends ${feature_pascal}State {
  const ${feature_pascal}Error(this.message);
  final String message;
}
"
  fi

  mkf "$BASE/business_logic/${name}_event.dart" "sealed class ${pascal}Event { const ${pascal}Event(); }

final class ${pascal}Load    extends ${pascal}Event { const ${pascal}Load(); }
final class ${pascal}Refresh extends ${pascal}Event { const ${pascal}Refresh(); }
// TODO: add events
"

  mkf "$BASE/business_logic/${name}_bloc.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${name}_event.dart';
import '${feature}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${feature_pascal}State> {
  ${pascal}Bloc(this._repository) : super(const ${feature_pascal}Initial()) {
    on<${pascal}Load>(_onLoad);
    on<${pascal}Refresh>(_onRefresh);
  }

  final ${pascal}Repository _repository;

  Future<void> _onLoad(${pascal}Load event, Emitter<${feature_pascal}State> emit) async {
    emit(const ${feature_pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      emit(${feature_pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${feature_pascal}Error(f.userMessage));
    }
  }

  Future<void> _onRefresh(${pascal}Refresh event, Emitter<${feature_pascal}State> emit) async {
    try {
      final items = await _repository.get${pascal}List();
      emit(${feature_pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${feature_pascal}Error(f.userMessage));
    }
  }
}
"
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
