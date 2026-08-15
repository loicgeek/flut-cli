import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/{{Feature}}_usecase.dart';
import '{{Feature}}_state.dart';

class {{Pascal}}Cubit extends Cubit<{{FeaturePascal}}State> {
  {{Pascal}}Cubit(this._useCase) : super(const {{FeaturePascal}}Initial());
  final {{FeaturePascal}}UseCase _useCase;

  Future<void> load() async {
    emit(const {{FeaturePascal}}Loading());
    try {
      final items = await _useCase(const NoParams());
      if (!isClosed) emit({{FeaturePascal}}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit({{FeaturePascal}}Error(f.userMessage));
    }
  }
}
