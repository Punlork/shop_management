part of 'auth_bloc.dart';

@immutable
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  const Authenticated(
    this.user,
  );

  final User user;

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}
