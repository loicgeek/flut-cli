import '../entities/{{name}}.dart';

/// Domain contract for {{name}} data access.
///
/// The implementation lives in data/repositories/. Use cases depend on this
/// interface only, which is what keeps the domain layer free of Dio and JSON.
abstract interface class {{Pascal}}Repository {
  Future<List<{{Pascal}}>> get{{Pascal}}List();

  // TODO: add the operations this feature needs
}
