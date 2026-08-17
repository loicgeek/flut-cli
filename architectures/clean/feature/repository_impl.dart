import '../../domain/entities/{{name}}.dart';
import '../../domain/repositories/{{name}}_repository.dart';
import '../datasources/{{name}}_remote_datasource.dart';

/// Implements the domain contract on top of the data sources.
///
/// Add caching or a local source here — the domain layer stays unchanged.
class {{Pascal}}RepositoryImpl implements {{Pascal}}Repository {
  const {{Pascal}}RepositoryImpl(this._remoteDataSource);
  final {{Pascal}}RemoteDataSource _remoteDataSource;

  @override
  Future<List<{{Pascal}}>> get{{Pascal}}List() {
    return _remoteDataSource.fetch{{Pascal}}List();
  }
}
