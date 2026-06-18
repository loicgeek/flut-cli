import '../data/models/auth_model.dart';

sealed class AuthState { const AuthState(); }

final class AuthInitial extends AuthState { const AuthInitial(); }
final class AuthLoading extends AuthState { const AuthLoading(); }
final class AuthLoaded  extends AuthState {
  const AuthLoaded(this.items);
  final List<AuthModel> items;
}
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
