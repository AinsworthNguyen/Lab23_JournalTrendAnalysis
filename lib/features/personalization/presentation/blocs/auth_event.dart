import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInRequested extends AuthEvent {}

class SignOutRequested extends AuthEvent {}

class BypassSignInRequested extends AuthEvent {}

class DirectEmailSignInRequested extends AuthEvent {
  final String email;
  const DirectEmailSignInRequested(this.email);

  @override
  List<Object?> get props => [email];
}
