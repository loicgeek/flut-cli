import '../data/models/user_profile_model.dart';

sealed class UserProfileState { const UserProfileState(); }

final class UserProfileInitial extends UserProfileState { const UserProfileInitial(); }
final class UserProfileLoading extends UserProfileState { const UserProfileLoading(); }
final class UserProfileLoaded  extends UserProfileState {
  const UserProfileLoaded(this.items);
  final List<UserProfileModel> items;
}
final class UserProfileError extends UserProfileState {
  const UserProfileError(this.message);
  final String message;
}
