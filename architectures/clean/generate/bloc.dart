import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/{{name}}_usecase.dart';
import '{{name}}_event.dart';
import '{{Feature}}_state.dart';

// Re-exported so a screen importing the bloc also sees its events.
export '{{name}}_event.dart';

class {{Pascal}}Bloc extends Bloc<{{Pascal}}Event, {{FeaturePascal}}State> {
  {{Pascal}}Bloc(this._useCase) : super(const {{FeaturePascal}}Initial()) {
    on<{{Pascal}}Load>(_onLoad);
    on<{{Pascal}}Refresh>(_onRefresh);
  }

  final {{Pascal}}UseCase _useCase;

  Future<void> _onLoad({{Pascal}}Load event, Emitter<{{FeaturePascal}}State> emit) async {
    emit(const {{FeaturePascal}}Loading());
    await _load(emit);
  }

  Future<void> _onRefresh({{Pascal}}Refresh event, Emitter<{{FeaturePascal}}State> emit) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<{{FeaturePascal}}State> emit) async {
    try {
      final items = await _useCase(const NoParams());
      emit({{FeaturePascal}}Loaded(items));
    } on AppFailure catch (f) {
      emit({{FeaturePascal}}Error(f.userMessage));
    }
  }
}
