import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/{{name}}_usecase.dart';
import '{{name}}_state.dart';

/// Presentation depends on the use case, not on the repository or Dio.
class {{Pascal}}Cubit extends Cubit<{{Pascal}}State> {
  {{Pascal}}Cubit(this._useCase) : super(const {{Pascal}}Initial());
  final {{Pascal}}UseCase _useCase;

  Future<void> load() async {
    emit(const {{Pascal}}Loading());
    try {
      final items = await _useCase(const NoParams());
      if (!isClosed) emit({{Pascal}}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit({{Pascal}}Error(f.userMessage));
    }
  }
}
