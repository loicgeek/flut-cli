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

  # --------------------------------------------------------------------------
  # Service layer (optional)
  # When --service: the Repository delegates to the Service.
  # The Service handles multi-source orchestration, caching, or transformation.
  # Without --service: the Repository handles data access directly.
  # --------------------------------------------------------------------------
  if [[ "$use_service" == true ]]; then
    mkf "$BASE/data/services/${name}_service.dart" "import '../models/${name}_model.dart';

/// ${pascal}Service handles data orchestration across multiple sources,
/// or any business logic that does not belong inside the repository itself.
///
/// Inject additional data sources (remote, local, cache) as constructor params.
///
/// Usage: the ${pascal}Repository delegates to this service.
class ${pascal}Service {
  const ${pascal}Service(
    // TODO: inject your data sources
    // this._remoteDataSource,
    // this._localDataSource,
  );

  Future<List<${pascal}Model>> get${pascal}List() async {
    // TODO: orchestrate sources, e.g. cache-first, merge, transform
    throw UnimplementedError();
  }
}
"
  fi

  # --------------------------------------------------------------------------
  # Repository
  # Bloc/Cubit always injects the Repository.
  # When --service, the Repository injects and delegates to the Service.
  # --------------------------------------------------------------------------
  if [[ "$use_service" == true ]]; then
    mkf "$BASE/data/repositories/${name}_repository.dart" "import 'package:dio/dio.dart';

import '../../../../core/error/exception_mapper.dart';
import '../../../../core/error/failures.dart';
import '../models/${name}_model.dart';
import '../services/${name}_service.dart';

class ${pascal}Repository {
  const ${pascal}Repository(this._service);

  /// The service handles multi-source orchestration.
  /// Add a Dio or remote data source here only if this repo also has
  /// its own direct network calls alongside the service.
  final ${pascal}Service _service;

  Future<List<${pascal}Model>> get${pascal}List() async {
    try {
      return await _service.get${pascal}List();
    } on DioException catch (e) {
      throw mapDioExceptionToFailure(e);
    } catch (e) {
      throw AppFailure.unexpected(message: e.toString());
    }
  }
}
"
  else
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
  fi

  # --------------------------------------------------------------------------
  # State — plain sealed class, zero codegen
  # --------------------------------------------------------------------------
  mkf "$BASE/business_logic/${name}_state.dart" "import '../data/models/${name}_model.dart';

sealed class ${pascal}State { const ${pascal}State(); }

final class ${pascal}Initial extends ${pascal}State { const ${pascal}Initial(); }
final class ${pascal}Loading extends ${pascal}State { const ${pascal}Loading(); }
final class ${pascal}Loaded  extends ${pascal}State {
  const ${pascal}Loaded(this.items);
  final List<${pascal}Model> items;
}
final class ${pascal}Error extends ${pascal}State {
  const ${pascal}Error(this.message);
  final String message;
}
"

  # --------------------------------------------------------------------------
  # Cubit or Bloc — always injects Repository
  # --------------------------------------------------------------------------
  if [[ "$use_bloc" == true ]]; then
    mkf "$BASE/business_logic/${name}_event.dart" "sealed class ${pascal}Event { const ${pascal}Event(); }

final class ${pascal}Load    extends ${pascal}Event { const ${pascal}Load(); }
final class ${pascal}Refresh extends ${pascal}Event { const ${pascal}Refresh(); }
// TODO: add events
"

    mkf "$BASE/business_logic/${name}_bloc.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${name}_event.dart';
import '${name}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc(this._repository) : super(const ${pascal}Initial()) {
    on<${pascal}Load>(_onLoad);
    on<${pascal}Refresh>(_onRefresh);
  }

  final ${pascal}Repository _repository;

  Future<void> _onLoad(${pascal}Load event, Emitter<${pascal}State> emit) async {
    emit(const ${pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      emit(${pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${pascal}Error(f.userMessage));
    }
  }

  Future<void> _onRefresh(${pascal}Refresh event, Emitter<${pascal}State> emit) async {
    try {
      final items = await _repository.get${pascal}List();
      emit(${pascal}Loaded(items));
    } on AppFailure catch (f) {
      emit(${pascal}Error(f.userMessage));
    }
  }
}
"
  else
    mkf "$BASE/business_logic/${name}_cubit.dart" "import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/${name}_repository.dart';
import '${name}_state.dart';

class ${pascal}Cubit extends Cubit<${pascal}State> {
  ${pascal}Cubit(this._repository) : super(const ${pascal}Initial());
  final ${pascal}Repository _repository;

  Future<void> load() async {
    emit(const ${pascal}Loading());
    try {
      final items = await _repository.get${pascal}List();
      if (!isClosed) emit(${pascal}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(${pascal}Error(f.userMessage));
    }
  }
}
"
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

  mkf "$BASE/presentation/router/${name}_router_module.dart" "import 'package:auto_route/auto_route.dart';

import 'package:${pkg_name}/core/custom_transition_builders.dart';
import '../screens/${name}_screen.dart';

part '${name}_router_module.g.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/${name}/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class ${pascal}RouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        transitionsBuilder: customTransitionBuilder,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: ${pascal}Route.page),
        // TODO: add more routes for this feature
      ];
}
"

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

  mkf "$BASE/presentation/screens/${name}_screen.dart" "import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/${bl_import}';
import '../../business_logic/${name}_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class ${pascal}Screen extends StatelessWidget {
  const ${pascal}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      ${bl_provide},
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
      body: BlocConsumer<${bl_type}, ${pascal}State>(
        listener: (context, state) {
          if (state is ${pascal}Error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          ${pascal}Initial() => const SizedBox.shrink(),
          ${pascal}Loading() => const Center(child: LoadingShimmer()),
          ${pascal}Error()   => ErrorState(
              message: (state as ${pascal}Error).message,
              onRetry: () => ${bl_retry},
            ),
          ${pascal}Loaded()  => _${pascal}List(
              items: (state as ${pascal}Loaded).items,
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
