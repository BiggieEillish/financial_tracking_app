import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_list_cubit.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_list_state.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockExpenseGroupRepository mockExpenseGroupRepository;
  late ExpenseListCubit cubit;

  setUp(() {
    mockExpenseGroupRepository = MockExpenseGroupRepository();
    cubit = ExpenseListCubit(
      mockExpenseGroupRepository,
      userId: TestData.testUserId,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ExpenseListCubit', () {
    test('initial state is ExpenseListInitial', () {
      expect(cubit.state, equals(ExpenseListInitial()));
    });

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits [Loading, Loaded] when loadExpenses succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        return cubit;
      },
      act: (cubit) => cubit.loadExpenses(),
      expect: () => [
        ExpenseListLoading(),
        ExpenseListLoaded(TestData.sampleExpenseGroups()),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .called(1);
      },
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits [Loading, Error] when loadExpenses fails',
      build: () {
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenThrow(Exception('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.loadExpenses(),
      expect: () => [
        ExpenseListLoading(),
        isA<ExpenseListError>()
            .having((state) => state.message, 'message', contains('Failed to load expenses')),
      ],
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits [Loading, Loaded] when deleteGroup succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.deleteExpenseGroup('group_1'))
            .thenAnswer((_) async => Future.value());
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        return cubit;
      },
      act: (cubit) => cubit.deleteGroup('group_1'),
      expect: () => [
        ExpenseListLoading(),
        ExpenseListLoaded(TestData.sampleExpenseGroups()),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.deleteExpenseGroup('group_1')).called(1);
        verify(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .called(1);
      },
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits Error when deleteGroup fails',
      build: () {
        when(() => mockExpenseGroupRepository.deleteExpenseGroup('group_1'))
            .thenThrow(Exception('Delete failed'));
        return cubit;
      },
      act: (cubit) => cubit.deleteGroup('group_1'),
      expect: () => [
        isA<ExpenseListError>()
            .having((state) => state.message, 'message', contains('Failed to delete expense')),
      ],
    );

    blocTest<ExpenseListCubit, ExpenseListState>(
      'emits [Loading, Loaded] with empty list when no expenses',
      build: () {
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadExpenses(),
      expect: () => [
        ExpenseListLoading(),
        const ExpenseListLoaded([]),
      ],
    );
  });
}
