import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/core/repositories/budget_repository_impl.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockDatabaseService mockDatabaseService;
  late BudgetRepositoryImpl repository;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    repository = BudgetRepositoryImpl(mockDatabaseService);
  });

  group('BudgetRepositoryImpl', () {
    group('getAllBudgets', () {
      test('returns all budgets from database service', () async {
        final budgets = TestData.sampleBudgets();
        when(() => mockDatabaseService.getAllBudgets())
            .thenAnswer((_) async => budgets);

        final result = await repository.getAllBudgets();

        expect(result, equals(budgets));
        expect(result.length, 3);
        verify(() => mockDatabaseService.getAllBudgets()).called(1);
      });

      test('returns empty list when no budgets', () async {
        when(() => mockDatabaseService.getAllBudgets())
            .thenAnswer((_) async => []);

        final result = await repository.getAllBudgets();

        expect(result, isEmpty);
      });

      test('propagates error from database service', () async {
        when(() => mockDatabaseService.getAllBudgets())
            .thenThrow(Exception('DB error'));

        expect(() => repository.getAllBudgets(), throwsException);
      });
    });

    group('getUserBudgets', () {
      test('returns budgets for specific user', () async {
        final budgets = TestData.sampleBudgets();
        when(() => mockDatabaseService.getUserBudgets(any()))
            .thenAnswer((_) async => budgets);

        final result = await repository.getUserBudgets(TestData.testUserId);

        expect(result, equals(budgets));
        verify(() => mockDatabaseService.getUserBudgets(TestData.testUserId))
            .called(1);
      });
    });

    group('addBudget', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.addBudget(
              userId: any(named: 'userId'),
              category: any(named: 'category'),
              limit: any(named: 'limit'),
              periodStart: any(named: 'periodStart'),
              periodEnd: any(named: 'periodEnd'),
            )).thenAnswer((_) async {});

        final start = DateTime(2026, 2, 1);
        final end = DateTime(2026, 2, 28);

        await repository.addBudget(
          userId: TestData.testUserId,
          category: 'Food',
          limit: 500.0,
          periodStart: start,
          periodEnd: end,
        );

        verify(() => mockDatabaseService.addBudget(
              userId: TestData.testUserId,
              category: 'Food',
              limit: 500.0,
              periodStart: start,
              periodEnd: end,
            )).called(1);
      });
    });

    group('updateBudget', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.updateBudget(
              id: any(named: 'id'),
              category: any(named: 'category'),
              limit: any(named: 'limit'),
              periodStart: any(named: 'periodStart'),
              periodEnd: any(named: 'periodEnd'),
            )).thenAnswer((_) async {});

        final start = DateTime(2026, 3, 1);
        final end = DateTime(2026, 3, 31);

        await repository.updateBudget(
          id: 'budget_1',
          category: 'Food',
          limit: 600.0,
          periodStart: start,
          periodEnd: end,
        );

        verify(() => mockDatabaseService.updateBudget(
              id: 'budget_1',
              category: 'Food',
              limit: 600.0,
              periodStart: start,
              periodEnd: end,
            )).called(1);
      });
    });

    group('deleteBudget', () {
      test('delegates to database service', () async {
        when(() => mockDatabaseService.deleteBudget(any()))
            .thenAnswer((_) async {});

        await repository.deleteBudget('budget_1');

        verify(() => mockDatabaseService.deleteBudget('budget_1')).called(1);
      });
    });
  });
}
