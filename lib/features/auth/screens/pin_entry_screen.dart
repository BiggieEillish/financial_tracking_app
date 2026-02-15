import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_cubit.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/auth/auth_service.dart';
import '../../../shared/constants/app_constants.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String? _error;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final authService = context.read<AuthService>();
    final available = await authService.isBiometricAvailable();
    final enabled = await authService.isBiometricEnabled();
    if (mounted) {
      setState(() => _biometricAvailable = available && enabled);
      if (_biometricAvailable) {
        context.read<AuthCubit>().unlockWithBiometrics();
      }
    }
  }

  void _onDigitPressed(int digit) {
    setState(() {
      _error = null;
      if (_pin.length < 4) {
        _pin += digit.toString();
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 200), () {
            context.read<AuthCubit>().unlock(_pin);
            setState(() => _pin = '');
          });
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _error = null;
      if (_pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/');
        } else if (state is AuthError) {
          setState(() => _error = state.message);
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
                  Icons.lock,
                  size: 64,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Enter Your PIN', style: AppTextStyles.headline2),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter your 4-digit PIN to unlock',
                  style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildPinDots(),
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
                const SizedBox(height: AppSpacing.md),
                if (_biometricAvailable)
                  TextButton.icon(
                    onPressed: () => context.read<AuthCubit>().unlockWithBiometrics(),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometrics'),
                  ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppConstants.primaryColor : Colors.transparent,
            border: Border.all(
              color: _error != null ? AppConstants.errorColor : AppConstants.primaryColor,
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
