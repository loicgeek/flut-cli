import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/{{Feature}}_repository.dart';
import '{{Feature}}_state.dart';

class {{Pascal}}Cubit extends Cubit<{{FeaturePascal}}State> {
  {{Pascal}}Cubit(this._repository) : super(const {{FeaturePascal}}Initial());
  final {{FeaturePascal}}Repository _repository;

  Future<void> load() async {
    emit(const {{FeaturePascal}}Loading());
    try {
      final items = await _repository.get{{FeaturePascal}}List();
      if (!isClosed) emit({{FeaturePascal}}Loaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit({{FeaturePascal}}Error(f.userMessage));
    }
  }
}

