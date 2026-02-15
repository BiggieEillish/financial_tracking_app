import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/core/auth/auth_cubit.dart';
import 'package:financial_planner_ui_demo/core/auth/auth_state.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockAuthService mockAuthService;
  late AuthCubit cubit;

  setUp(() {
    mockAuthService = MockAuthService();
    cubit = AuthCubit(mockAuthService);
  });

  tearDown(() {
    cubit.close();
  });

  group('AuthCubit', () {
    test('initial state is AuthInitial', () {
      expect(cubit.state, equals(const AuthInitial()));
    });

    test('userId getter returns null initially', () {
      expect(cubit.userId, isNull);
    });

    blocTest<AuthCubit, AuthState>(
      'emits SetupRequired when checkAuth finds no PIN',
      build: () {
        when(() => mockAuthService.isPinSet()).thenAnswer((_) async => false);
        return cubit;
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [const AuthSetupRequired()],
      verify: (_) {
        verify(() => mockAuthService.isPinSet()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits Locked when checkAuth finds PIN is set',
      build: () {
        when(() => mockAuthService.isPinSet()).thenAnswer((_) async => true);
        return cubit;
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [const AuthLocked()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits Error when checkAuth fails',
      build: () {
        when(() => mockAuthService.isPinSet()).thenThrow(Exception('Auth error'));
        return cubit;
      },
      act: (cubit) => cubit.checkAuth(),
      expect: () => [
        isA<AuthError>()
            .having((state) => state.message, 'message', contains('Failed to check auth')),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits Authenticated and sets userId when setupPin succeeds',
      build: () {
        when(() => mockAuthService.setPin(any())).thenAnswer((_) async => Future.value());
        when(() => mockAuthService.getUserId()).thenAnswer((_) async => TestData.testUserId);
        return cubit;
      },
      act: (cubit) => cubit.setupPin('1234'),
      expect: () => [AuthAuthenticated(TestData.testUserId)],
      verify: (_) {
        verify(() => mockAuthService.setPin('1234')).called(1);
        verify(() => mockAuthService.getUserId()).called(1);
        expect(cubit.userId, equals(TestData.testUserId));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits Error when setupPin fails',
      build: () {
        when(() => mockAuthService.setPin(any())).thenThrow(Exception('Setup failed'));
        return cubit;
      },
      act: (cubit) => cubit.setupPin('1234'),
      expect: () => [
        isA<AuthError>()
            .having((state) => state.message, 'message', contains('Failed to setup PIN')),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits Authenticated when unlock with correct PIN',
      build: () {
        when(() => mockAuthService.verifyPin(any())).thenAnswer((_) async => true);
        when(() => mockAuthService.getUserId()).thenAnswer((_) async => TestData.testUserId);
        return cubit;
      },
      act: (cubit) => cubit.unlock('1234'),
      expect: () => [AuthAuthenticated(TestData.testUserId)],
      verify: (_) {
        verify(() => mockAuthService.verifyPin('1234')).called(1);
        verify(() => mockAuthService.getUserId()).called(1);
        expect(cubit.userId, equals(TestData.testUserId));
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits Error then Locked when unlock with wrong PIN',
      build: () {
        when(() => mockAuthService.verifyPin(any())).thenAnswer((_) async => false);
        return cubit;
      },
      act: (cubit) => cubit.unlock('0000'),
      expect: () => [
        const AuthError('Incorrect PIN'),
        const AuthLocked(),
      ],
      verify: (_) {
        verify(() => mockAuthService.verifyPin('0000')).called(1);
        verifyNever(() => mockAuthService.getUserId());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits Error when unlock fails with exception',
      build: () {
        when(() => mockAuthService.verifyPin(any())).thenThrow(Exception('Verify failed'));
        return cubit;
      },
      act: (cubit) => cubit.unlock('1234'),
      expect: () => [
        isA<AuthError>()
            .having((state) => state.message, 'message', contains('Failed to unlock')),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'emits Authenticated when unlockWithBiometrics succeeds',
      build: () {
        when(() => mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);
        when(() => mockAuthService.authenticateWithBiometrics()).thenAnswer((_) async => true);
        when(() => mockAuthService.getUserId()).thenAnswer((_) async => TestData.testUserId);
        return cubit;
      },
      act: (cubit) => cubit.unlockWithBiometrics(),
      expect: () => [AuthAuthenticated(TestData.testUserId)],
      verify: (_) {
        verify(() => mockAuthService.isBiometricEnabled()).called(1);
        verify(() => mockAuthService.authenticateWithBiometrics()).called(1);
        verify(() => mockAuthService.getUserId()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'does not emit when biometrics not enabled',
      build: () {
        when(() => mockAuthService.isBiometricEnabled()).thenAnswer((_) async => false);
        return cubit;
      },
      act: (cubit) => cubit.unlockWithBiometrics(),
      expect: () => [],
      verify: (_) {
        verify(() => mockAuthService.isBiometricEnabled()).called(1);
        verifyNever(() => mockAuthService.authenticateWithBiometrics());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'does not emit when biometric authentication fails',
      build: () {
        when(() => mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);
        when(() => mockAuthService.authenticateWithBiometrics()).thenAnswer((_) async => false);
        return cubit;
      },
      act: (cubit) => cubit.unlockWithBiometrics(),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockAuthService.getUserId());
      },
    );

    blocTest<AuthCubit, AuthState>(
      'emits Error when unlockWithBiometrics fails',
      build: () {
        when(() => mockAuthService.isBiometricEnabled())
            .thenThrow(Exception('Biometric error'));
        return cubit;
      },
      act: (cubit) => cubit.unlockWithBiometrics(),
      expect: () => [
        isA<AuthError>()
            .having((state) => state.message, 'message', contains('Biometric auth failed')),
      ],
    );

    test('changePin returns true when successful', () async {
      when(() => mockAuthService.changePin(any(), any())).thenAnswer((_) async => true);

      final result = await cubit.changePin('1234', '5678');

      expect(result, isTrue);
      verify(() => mockAuthService.changePin('1234', '5678')).called(1);
    });

    test('changePin returns false and emits Error when fails', () async {
      when(() => mockAuthService.changePin(any(), any())).thenThrow(Exception('Change failed'));

      final result = await cubit.changePin('1234', '5678');

      expect(result, isFalse);
      expect(cubit.state, isA<AuthError>());
    });

    blocTest<AuthCubit, AuthState>(
      'emits Locked and clears userId when lock is called',
      build: () => cubit,
      seed: () => AuthAuthenticated(TestData.testUserId),
      act: (cubit) {
        cubit.lock();
      },
      expect: () => [const AuthLocked()],
      verify: (_) {
        expect(cubit.userId, isNull);
      },
    );
  });
}
