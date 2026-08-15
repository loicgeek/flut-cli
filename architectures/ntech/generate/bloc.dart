import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/{{Feature}}_repository.dart';
import '{{name}}_event.dart';
import '{{Feature}}_state.dart';

// Re-exported so a screen importing the bloc also sees its events.
export '{{name}}_event.dart';

class {{Pascal}}Bloc extends Bloc<{{Pascal}}Event, {{FeaturePascal}}State> {
  {{Pascal}}Bloc(this._repository) : super(const {{FeaturePascal}}Initial()) {
    on<{{Pascal}}Load>(_onLoad);
    on<{{Pascal}}Refresh>(_onRefresh);
  }

  final {{FeaturePascal}}Repository _repository;

  Future<void> _onLoad({{Pascal}}Load event, Emitter<{{FeaturePascal}}State> emit) async {
    emit(const {{FeaturePascal}}Loading());
    try {
      final items = await _repository.get{{FeaturePascal}}List();
      emit({{FeaturePascal}}Loaded(items));
    } on AppFailure catch (f) {
      emit({{FeaturePascal}}Error(f.userMessage));
    }
  }

  Future<void> _onRefresh({{Pascal}}Refresh event, Emitter<{{FeaturePascal}}State> emit) async {
    try {
      final items = await _repository.get{{FeaturePascal}}List();
      emit({{FeaturePascal}}Loaded(items));
    } on AppFailure catch (f) {
      emit({{FeaturePascal}}Error(f.userMessage));
    }
  }
}

