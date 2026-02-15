import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  String? _currentUserId;

  AuthCubit(this._authService) : super(const AuthInitial());

  String? get userId => _currentUserId;

  Future<void> checkAuth() async {
    try {
      final hasPIN = await _authService.isPinSet();
      if (!hasPIN) {
        emit(const AuthSetupRequired());
      } else {
        emit(const AuthLocked());
      }
    } catch (e) {
      emit(AuthError('Failed to check auth: $e'));
    }
  }

  Future<void> setupPin(String pin) async {
    try {
      await _authService.setPin(pin);
      _currentUserId = await _authService.getUserId();
      emit(AuthAuthenticated(_currentUserId!));
    } catch (e) {
      emit(AuthError('Failed to setup PIN: $e'));
    }
  }

  Future<void> unlock(String pin) async {
    try {
      final isValid = await _authService.verifyPin(pin);
      if (isValid) {
        _currentUserId = await _authService.getUserId();
        emit(AuthAuthenticated(_currentUserId!));
      } else {
        emit(const AuthError('Incorrect PIN'));
        emit(const AuthLocked());
      }
    } catch (e) {
      emit(AuthError('Failed to unlock: $e'));
    }
  }

  Future<void> unlockWithBiometrics() async {
    try {
      final isEnabled = await _authService.isBiometricEnabled();
      if (!isEnabled) return;

      final success = await _authService.authenticateWithBiometrics();
      if (success) {
        _currentUserId = await _authService.getUserId();
        emit(AuthAuthenticated(_currentUserId!));
      }
    } catch (e) {
      emit(AuthError('Biometric auth failed: $e'));
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      return await _authService.changePin(oldPin, newPin);
    } catch (e) {
      emit(AuthError('Failed to change PIN: $e'));
      return false;
    }
  }

  void lock() {
    _currentUserId = null;
    emit(const AuthLocked());
  }
}
