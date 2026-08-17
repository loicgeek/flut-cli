import '../models/{{name}}_model.dart';

/// {{Pascal}}Service handles data orchestration across multiple sources,
/// or any business logic that does not belong inside the repository itself.
///
/// Inject additional data sources (remote, local, cache) as constructor params.
///
/// Usage: the {{Pascal}}Repository delegates to this service.
class {{Pascal}}Service {
  const {{Pascal}}Service(
    // TODO: inject your data sources
    // this._remoteDataSource,
    // this._localDataSource,
  );

  Future<List<{{Pascal}}Model>> get{{Pascal}}List() async {
    // TODO: orchestrate sources, e.g. cache-first, merge, transform
    throw UnimplementedError();
  }
}

