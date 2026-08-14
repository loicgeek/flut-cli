import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/{{name}}_repository.dart';
import '{{name}}_state.dart';

class {{Pascal}}Cubit extends Cubit<{{Pascal}}State> {
  {{Pascal}}Cubit(this._repository) : super(const {{Pascal}}Initial());
  final {{Pascal}}Repository _repository;

  Future<void> load() async {
    emit(const {{Pascal}}Loading());
    try {
      final items = await _repository.get{{Pascal}}List();
      if (!isClosed) emit({{Pascal}}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit({{Pascal}}Error(f.userMessage));
    }
  }
}

