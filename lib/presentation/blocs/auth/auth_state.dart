import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthenticatedAsOwner extends AuthState {
  final String uid;
  final String email;

  const AuthenticatedAsOwner({required this.uid, required this.email});

  @override
  List<Object?> get props => [uid, email];
}

class AuthenticatedAsKasir extends AuthState {
  final String ownerId;

  const AuthenticatedAsKasir({required this.ownerId});

  @override
  List<Object?> get props => [ownerId];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
