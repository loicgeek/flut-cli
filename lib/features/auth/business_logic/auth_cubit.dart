import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthInitial());
  final AuthRepository _repository;

  Future<void> load() async {
    emit(const AuthLoading());
    try {
      final items = await _repository.getAuthList();
      if (!isClosed) emit(AuthLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AuthError(f.userMessage));
    }
  }
}
