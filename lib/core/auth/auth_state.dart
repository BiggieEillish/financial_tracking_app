import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthSetupRequired extends AuthState {
  const AuthSetupRequired();
}

class AuthLocked extends AuthState {
  const AuthLocked();
}

class AuthAuthenticated extends AuthState {
  final String userId;
  const AuthAuthenticated(this.userId);
  @override
  List<Object?> get props => [userId];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
