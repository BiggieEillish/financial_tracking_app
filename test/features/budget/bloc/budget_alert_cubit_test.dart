import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_alert_cubit.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_alert_state.dart';
import 'package:financial_planner_ui_demo/core/services/notification_service.dart';
import 'package:financial_planner_ui_demo/core/models/expense_group_with_items.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockBudgetRepository mockBudgetRepository;
  late MockExpenseGroupRepository mockExpenseGroupRepository;
  late BudgetAlertCubit cubit;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    mockBudgetRepository = MockBudgetRepository();
    mockExpenseGroupRepository = MockExpenseGroupRepository();
    cubit = BudgetAlertCubit(mockBudgetRepository, mockExpenseGroupRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('BudgetAlertCubit', () {
    test('initial state is BudgetAlertInitial', () {
      expect(cubit.state, equals(BudgetAlertInitial()));
    });

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'emits [Loading, Loaded] with no alerts when spending is under 80%',
      build: () {
        final budget = TestData.makeBudget(
          category: 'Food',
          limit: 500.0,
          periodStart: DateTime(2026, 2, 1),
          periodEnd: DateTime(2026, 2, 28),
        );
        final expenseGroups = [
          ExpenseGroupWithItems(
            group: TestData.makeExpenseGroup(
              id: 'g1',
              date: DateTime(2026, 2, 15),
            ),
            items: [
              TestData.makeExpenseItem(
                id: 'i1',
                groupId: 'g1',
                category: 'Food',
                amount: 300.0,
              ),
            ],
          ),
        ];
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenAnswer((_) async => [budget]);
        when(() => mockExpenseGroupRepository.getExpenseGroupsByDateRange(
              TestData.testUserId,
              any(),
              any(),
            )).thenAnswer((_) async => expenseGroups);
        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        const BudgetAlertLoaded([]),
      ],
      verify: (_) {
        verify(() => mockBudgetRepository.getUserBudgets(TestData.testUserId)).called(1);
        verify(() => mockExpenseGroupRepository.getExpenseGroupsByDateRange(
              TestData.testUserId,
              any(),
              any(),
            )).called(1);
      },
    );

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'emits [Loading, Loaded] with warning alert when spending is at 85%',
      build: () {
        final budget = TestData.makeBudget(
          category: 'Food',
          limit: 500.0,
          periodStart: DateTime(2026, 2, 1),
          periodEnd: DateTime(2026, 2, 28),
        );
        final expenseGroups = [
          ExpenseGroupWithItems(
            group: TestData.makeExpenseGroup(
              id: 'g1',
              date: DateTime(2026, 2, 15),
            ),
            items: [
              TestData.makeExpenseItem(
                id: 'i1',
                groupId: 'g1',
                category: 'Food',
                amount: 425.0,
              ),
            ],
          ),
        ];
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenAnswer((_) async => [budget]);
        when(() => mockExpenseGroupRepository.getExpenseGroupsByDateRange(
              TestData.testUserId,
              any(),
              any(),
            )).thenAnswer((_) async => expenseGroups);
        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        isA<BudgetAlertLoaded>().having(
          (state) => state.alerts.length,
          'alerts length',
          1,
        ).having(
          (state) => state.alerts.first.level,
          'alert level',
          AlertLevel.warning,
        ).having(
          (state) => state.alerts.first.category,
          'alert category',
          'Food',
        ).having(
          (state) => state.alerts.first.spent,
          'alert spent',
          425.0,
        ).having(
          (state) => state.alerts.first.limit,
          'alert limit',
          500.0,
        ),
      ],
    );

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'emits [Loading, Loaded] with critical alert when spending is at 100% or more',
      build: () {
        final budget = TestData.makeBudget(
          category: 'Food',
          limit: 500.0,
          periodStart: DateTime(2026, 2, 1),
          periodEnd: DateTime(2026, 2, 28),
        );
        final expenseGroups = [
          ExpenseGroupWithItems(
            group: TestData.makeExpenseGroup(
              id: 'g1',
              date: DateTime(2026, 2, 15),
            ),
            items: [
              TestData.makeExpenseItem(
                id: 'i1',
                groupId: 'g1',
                category: 'Food',
                amount: 550.0,
              ),
            ],
          ),
        ];
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenAnswer((_) async => [budget]);
        when(() => mockExpenseGroupRepository.getExpenseGroupsByDateRange(
              TestData.testUserId,
              any(),
              any(),
            )).thenAnswer((_) async => expenseGroups);
        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        isA<BudgetAlertLoaded>().having(
          (state) => state.alerts.length,
          'alerts length',
          1,
        ).having(
          (state) => state.alerts.first.level,
          'alert level',
          AlertLevel.critical,
        ).having(
          (state) => state.alerts.first.percentage,
          'percentage',
          closeTo(110.0, 0.01),
        ),
      ],
    );

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'only includes expenses matching budget category',
      build: () {
        final budget = TestData.makeBudget(
          category: 'Food',
          limit: 500.0,
          periodStart: DateTime(2026, 2, 1),
          periodEnd: DateTime(2026, 2, 28),
        );
        final expenseGroups = [
          ExpenseGroupWithItems(
            group: TestData.makeExpenseGroup(
              id: 'g1',
              date: DateTime(2026, 2, 15),
            ),
            items: [
              TestData.makeExpenseItem(
                id: 'i1',
                groupId: 'g1',
                category: 'Food',
                amount: 400.0,
              ),
            ],
          ),
          ExpenseGroupWithItems(
            group: TestData.makeExpenseGroup(
              id: 'g2',
              date: DateTime(2026, 2, 15),
            ),
            items: [
              TestData.makeExpenseItem(
                id: 'i2',
                groupId: 'g2',
                category: 'Transport',
                amount: 200.0,
              ),
            ],
          ),
        ];
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenAnswer((_) async => [budget]);
        when(() => mockExpenseGroupRepository.getExpenseGroupsByDateRange(
              TestData.testUserId,
              any(),
              any(),
            )).thenAnswer((_) async => expenseGroups);
        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        isA<BudgetAlertLoaded>().having(
          (state) => state.alerts.length,
          'alerts length',
          1,
        ).having(
          (state) => state.alerts.first.spent,
          'spent amount',
          400.0,
        ),
      ],
    );

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'emits [Loading, Error] when checkAlerts fails',
      build: () {
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenThrow(Exception('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        isA<BudgetAlertError>()
            .having((state) => state.message, 'message', contains('Failed to check budget alerts')),
      ],
    );

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'emits [Loading, Loaded] with empty alerts when no budgets exist',
      build: () {
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        const BudgetAlertLoaded([]),
      ],
    );

    blocTest<BudgetAlertCubit, BudgetAlertState>(
      'handles multiple budgets with mixed alert levels',
      build: () {
        final budgets = [
          TestData.makeBudget(
            id: 'b1',
            category: 'Food',
            limit: 500.0,
          ),
          TestData.makeBudget(
            id: 'b2',
            category: 'Transport',
            limit: 300.0,
          ),
          TestData.makeBudget(
            id: 'b3',
            category: 'Shopping',
            limit: 200.0,
          ),
        ];
        when(() => mockBudgetRepository.getUserBudgets(TestData.testUserId))
            .thenAnswer((_) async => budgets);

        // All budgets share the same period dates, so use any() and return
        // all relevant expenses; the cubit filters by category.
        when(() => mockExpenseGroupRepository.getExpenseGroupsByDateRange(
              TestData.testUserId,
              any(),
              any(),
            )).thenAnswer((_) async => [
              ExpenseGroupWithItems(
                group: TestData.makeExpenseGroup(id: 'g1'),
                items: [
                  TestData.makeExpenseItem(
                    id: 'i1',
                    groupId: 'g1',
                    category: 'Food',
                    amount: 450.0,
                  ),
                ],
              ),
              ExpenseGroupWithItems(
                group: TestData.makeExpenseGroup(id: 'g2'),
                items: [
                  TestData.makeExpenseItem(
                    id: 'i2',
                    groupId: 'g2',
                    category: 'Transport',
                    amount: 320.0,
                  ),
                ],
              ),
              ExpenseGroupWithItems(
                group: TestData.makeExpenseGroup(id: 'g3'),
                items: [
                  TestData.makeExpenseItem(
                    id: 'i3',
                    groupId: 'g3',
                    category: 'Shopping',
                    amount: 100.0,
                  ),
                ],
              ),
            ]);

        return cubit;
      },
      act: (cubit) => cubit.checkAlerts(TestData.testUserId),
      expect: () => [
        BudgetAlertLoading(),
        isA<BudgetAlertLoaded>().having(
          (state) => state.alerts.length,
          'alerts length',
          2,
        ).having(
          (state) => state.alerts.where((a) => a.level == AlertLevel.warning).length,
          'warning alerts',
          1,
        ).having(
          (state) => state.alerts.where((a) => a.level == AlertLevel.critical).length,
          'critical alerts',
          1,
        ),
      ],
    );
  });
}
