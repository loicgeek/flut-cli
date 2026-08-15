import '../../../../core/usecase/usecase.dart';
import '../entities/{{name}}.dart';
import '../repositories/{{name}}_repository.dart';

/// One unit of business logic.
///
/// Depends on the repository *interface*, never on its implementation, so it
/// can be unit-tested with a fake repository and no HTTP layer.
class {{Pascal}}UseCase implements UseCase<List<{{Pascal}}>, NoParams> {
  const {{Pascal}}UseCase(this._repository);
  final {{Pascal}}Repository _repository;

  @override
  Future<List<{{Pascal}}>> call(NoParams params) {
    // TODO: add business rules (filtering, sorting, validation) here
    return _repository.get{{Pascal}}List();
  }
}
