import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/auth_state.dart';
import '../../../shared/constants/app_constants.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _error;

  void _onDigitPressed(int digit) {
    setState(() {
      _error = null;
      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += digit.toString();
          if (_pin.length == 4) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() {
                  _isConfirming = true;
                });
              }
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit.toString();
          if (_confirmPin.length == 4) {
            Future.delayed(const Duration(milliseconds: 200), () {
              _validateAndSetup();
            });
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _error = null;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  void _validateAndSetup() {
    if (_pin == _confirmPin) {
      context.read<AuthCubit>().setupPin(_pin);
    } else {
      setState(() {
        _error = 'PINs do not match. Try again.';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                const Spacer(),
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isConfirming ? 'Confirm Your PIN' : 'Create a PIN',
                  style: AppTextStyles.headline2,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _isConfirming
                      ? 'Enter your PIN again to confirm'
                      : 'Set up a 4-digit PIN to secure your data',
                  style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildPinDots(_isConfirming ? _confirmPin : _pin),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _error!,
                    style: AppTextStyles.bodyText2.copyWith(
                      color: AppConstants.errorColor,
                    ),
                  ),
                ],
                const Spacer(),
                _buildNumberPad(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(String currentPin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < currentPin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppConstants.primaryColor : Colors.transparent,
            border: Border.all(
              color: AppConstants.primaryColor,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((d) => _buildDigitButton(d)).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [4, 5, 6].map((d) => _buildDigitButton(d)).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [7, 8, 9].map((d) => _buildDigitButton(d)).toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72),
            _buildDigitButton(0),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDigitButton(int digit) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: () => _onDigitPressed(digit),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey[100],
        ),
        child: Text(
          digit.toString(),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        onPressed: _onBackspace,
        style: TextButton.styleFrom(shape: const CircleBorder()),
        child: const Icon(Icons.backspace_outlined, size: 24),
      ),
    );
  }
}
