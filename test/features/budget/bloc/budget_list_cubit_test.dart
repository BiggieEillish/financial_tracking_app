import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_list_cubit.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_list_state.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockBudgetRepository mockBudgetRepository;
  late MockExpenseGroupRepository mockExpenseGroupRepository;
  late BudgetListCubit cubit;

  setUp(() {
    mockBudgetRepository = MockBudgetRepository();
    mockExpenseGroupRepository = MockExpenseGroupRepository();
    cubit = BudgetListCubit(mockBudgetRepository, mockExpenseGroupRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('BudgetListCubit', () {
    test('initial state is BudgetListInitial', () {
      expect(cubit.state, equals(BudgetListInitial()));
    });

    blocTest<BudgetListCubit, BudgetListState>(
      'emits [Loading, Loaded] when loadBudgets succeeds',
      build: () {
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => TestData.sampleBudgets());
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        return cubit;
      },
      act: (cubit) => cubit.loadBudgets(),
      expect: () => [
        BudgetListLoading(),
        isA<BudgetListLoaded>()
            .having((state) => state.budgets, 'budgets', TestData.sampleBudgets())
            .having((state) => state.expenseGroups, 'expenseGroups', TestData.sampleExpenseGroups()),
      ],
      verify: (_) {
        verify(() => mockBudgetRepository.getAllBudgets()).called(1);
        verify(() => mockExpenseGroupRepository.getAllExpenseGroups()).called(1);
      },
    );

    blocTest<BudgetListCubit, BudgetListState>(
      'emits [Loading, Error] when loadBudgets fails',
      build: () {
        when(() => mockBudgetRepository.getAllBudgets())
            .thenThrow(Exception('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.loadBudgets(),
      expect: () => [
        BudgetListLoading(),
        isA<BudgetListError>()
            .having((state) => state.message, 'message', contains('Failed to load budgets')),
      ],
    );

    blocTest<BudgetListCubit, BudgetListState>(
      'emits [Loading, Error] when expenses fetch fails',
      build: () {
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => TestData.sampleBudgets());
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenThrow(Exception('Expenses error'));
        return cubit;
      },
      act: (cubit) => cubit.loadBudgets(),
      expect: () => [
        BudgetListLoading(),
        isA<BudgetListError>()
            .having((state) => state.message, 'message', contains('Failed to load budgets')),
      ],
    );

    blocTest<BudgetListCubit, BudgetListState>(
      'emits [Loading, Loaded] when deleteBudget succeeds',
      build: () {
        when(() => mockBudgetRepository.deleteBudget(any()))
            .thenAnswer((_) async => Future.value());
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => TestData.sampleBudgets());
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        return cubit;
      },
      act: (cubit) => cubit.deleteBudget('budget_1'),
      expect: () => [
        BudgetListLoading(),
        isA<BudgetListLoaded>()
            .having((state) => state.budgets, 'budgets', TestData.sampleBudgets())
            .having((state) => state.expenseGroups, 'expenseGroups', TestData.sampleExpenseGroups()),
      ],
      verify: (_) {
        verify(() => mockBudgetRepository.deleteBudget('budget_1')).called(1);
        verify(() => mockBudgetRepository.getAllBudgets()).called(1);
        verify(() => mockExpenseGroupRepository.getAllExpenseGroups()).called(1);
      },
    );

    blocTest<BudgetListCubit, BudgetListState>(
      'emits Error when deleteBudget fails',
      build: () {
        when(() => mockBudgetRepository.deleteBudget(any()))
            .thenThrow(Exception('Delete failed'));
        return cubit;
      },
      act: (cubit) => cubit.deleteBudget('budget_1'),
      expect: () => [
        isA<BudgetListError>()
            .having((state) => state.message, 'message', contains('Failed to delete budget')),
      ],
    );

    blocTest<BudgetListCubit, BudgetListState>(
      'emits [Loading, Loaded] with empty lists when no data',
      build: () {
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => []);
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadBudgets(),
      expect: () => [
        BudgetListLoading(),
        const BudgetListLoaded(budgets: [], expenseGroups: []),
      ],
    );
  });
}
