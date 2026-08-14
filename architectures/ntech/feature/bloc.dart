import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/{{name}}_repository.dart';
import '{{name}}_event.dart';
import '{{name}}_state.dart';

class {{Pascal}}Bloc extends Bloc<{{Pascal}}Event, {{Pascal}}State> {
  {{Pascal}}Bloc(this._repository) : super(const {{Pascal}}Initial()) {
    on<{{Pascal}}Load>(_onLoad);
    on<{{Pascal}}Refresh>(_onRefresh);
  }

  final {{Pascal}}Repository _repository;

  Future<void> _onLoad({{Pascal}}Load event, Emitter<{{Pascal}}State> emit) async {
    emit(const {{Pascal}}Loading());
    try {
      final items = await _repository.get{{Pascal}}List();
      emit({{Pascal}}Loaded(items));
    } on AppFailure catch (f) {
      emit({{Pascal}}Error(f.userMessage));
    }
  }

  Future<void> _onRefresh({{Pascal}}Refresh event, Emitter<{{Pascal}}State> emit) async {
    try {
      final items = await _repository.get{{Pascal}}List();
      emit({{Pascal}}Loaded(items));
    } on AppFailure catch (f) {
      emit({{Pascal}}Error(f.userMessage));
    }
  }
}

