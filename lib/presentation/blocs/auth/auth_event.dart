import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class SignInWithGoogleEvent extends AuthEvent {}

class SignInWithPinEvent extends AuthEvent {
  final String pin;

  const SignInWithPinEvent(this.pin);

  @override
  List<Object?> get props => [pin];
}

class SignOutEvent extends AuthEvent {}
