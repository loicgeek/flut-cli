import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/{{name}}_usecase.dart';
import '{{name}}_event.dart';
import '{{name}}_state.dart';

// Re-exported so a screen importing the bloc also sees its events.
export '{{name}}_event.dart';

/// Presentation depends on the use case, not on the repository or Dio.
class {{Pascal}}Bloc extends Bloc<{{Pascal}}Event, {{Pascal}}State> {
  {{Pascal}}Bloc(this._useCase) : super(const {{Pascal}}Initial()) {
    on<{{Pascal}}Load>(_onLoad);
    on<{{Pascal}}Refresh>(_onRefresh);
  }

  final {{Pascal}}UseCase _useCase;

  Future<void> _onLoad({{Pascal}}Load event, Emitter<{{Pascal}}State> emit) async {
    emit(const {{Pascal}}Loading());
    await _load(emit);
  }

  Future<void> _onRefresh({{Pascal}}Refresh event, Emitter<{{Pascal}}State> emit) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<{{Pascal}}State> emit) async {
    try {
      final items = await _useCase(const NoParams());
      emit({{Pascal}}Loaded(items));
    } on AppFailure catch (f) {
      emit({{Pascal}}Error(f.userMessage));
    }
  }
}
