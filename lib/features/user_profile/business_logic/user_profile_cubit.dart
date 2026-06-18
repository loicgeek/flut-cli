import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/user_profile_repository.dart';
import 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  UserProfileCubit(this._repository) : super(const UserProfileInitial());
  final UserProfileRepository _repository;

  Future<void> load() async {
    emit(const UserProfileLoading());
    try {
      final items = await _repository.getUserProfileList();
      if (!isClosed) emit(UserProfileLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(UserProfileError(f.userMessage));
    }
  }
}
