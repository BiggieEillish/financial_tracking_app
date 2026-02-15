import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/reports/bloc/reports_cubit.dart';
import 'package:financial_planner_ui_demo/features/reports/bloc/reports_state.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockExpenseGroupRepository mockExpenseGroupRepository;
  late MockBudgetRepository mockBudgetRepository;
  late ReportsCubit cubit;

  setUp(() {
    mockExpenseGroupRepository = MockExpenseGroupRepository();
    mockBudgetRepository = MockBudgetRepository();
    cubit = ReportsCubit(
      expenseGroupRepository: mockExpenseGroupRepository,
      budgetRepository: mockBudgetRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ReportsCubit', () {
    test('initial state is ReportsInitial', () {
      expect(cubit.state, equals(const ReportsInitial()));
    });

    blocTest<ReportsCubit, ReportsState>(
      'emits [Loading, Loaded] with default period when loadReports succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => TestData.sampleBudgets());
        return cubit;
      },
      act: (cubit) => cubit.loadReports(),
      expect: () => [
        const ReportsLoading(),
        isA<ReportsLoaded>()
            .having((state) => state.groups, 'groups', TestData.sampleExpenseGroups())
            .having((state) => state.budgets, 'budgets', TestData.sampleBudgets())
            .having((state) => state.selectedPeriod, 'selectedPeriod', 'This Month'),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.getAllExpenseGroups()).called(1);
        verify(() => mockBudgetRepository.getAllBudgets()).called(1);
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits Error when loadReports fails due to expenses error',
      build: () {
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenThrow(Exception('Expenses error'));
        return cubit;
      },
      act: (cubit) => cubit.loadReports(),
      expect: () => [
        const ReportsLoading(),
        isA<ReportsError>()
            .having((state) => state.message, 'message', contains('Failed to load reports')),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits Error when loadReports fails due to budgets error',
      build: () {
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        when(() => mockBudgetRepository.getAllBudgets())
            .thenThrow(Exception('Budgets error'));
        return cubit;
      },
      act: (cubit) => cubit.loadReports(),
      expect: () => [
        const ReportsLoading(),
        isA<ReportsError>()
            .having((state) => state.message, 'message', contains('Failed to load reports')),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits new Loaded state with updated period when changePeriod is called',
      build: () {
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => TestData.sampleBudgets());
        return cubit;
      },
      seed: () => ReportsLoaded(
        groups: TestData.sampleExpenseGroups(),
        budgets: TestData.sampleBudgets(),
        selectedPeriod: 'This Month',
      ),
      act: (cubit) => cubit.changePeriod('This Week'),
      expect: () => [
        isA<ReportsLoaded>()
            .having((state) => state.selectedPeriod, 'selectedPeriod', 'This Week')
            .having((state) => state.groups, 'groups', TestData.sampleExpenseGroups())
            .having((state) => state.budgets, 'budgets', TestData.sampleBudgets()),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'changePeriod does nothing when state is not Loaded',
      build: () => cubit,
      seed: () => const ReportsLoading(),
      act: (cubit) => cubit.changePeriod('This Week'),
      expect: () => [],
    );

    blocTest<ReportsCubit, ReportsState>(
      'emits [Loading, Loaded] with empty lists when no data',
      build: () {
        when(() => mockExpenseGroupRepository.getAllExpenseGroups())
            .thenAnswer((_) async => []);
        when(() => mockBudgetRepository.getAllBudgets())
            .thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadReports(),
      expect: () => [
        const ReportsLoading(),
        const ReportsLoaded(
          groups: [],
          budgets: [],
          selectedPeriod: 'This Month',
        ),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'can change period multiple times',
      build: () => cubit,
      seed: () => ReportsLoaded(
        groups: TestData.sampleExpenseGroups(),
        budgets: TestData.sampleBudgets(),
        selectedPeriod: 'This Month',
      ),
      act: (cubit) async {
        cubit.changePeriod('This Week');
        cubit.changePeriod('This Year');
        cubit.changePeriod('All Time');
      },
      expect: () => [
        isA<ReportsLoaded>()
            .having((state) => state.selectedPeriod, 'selectedPeriod', 'This Week'),
        isA<ReportsLoaded>()
            .having((state) => state.selectedPeriod, 'selectedPeriod', 'This Year'),
        isA<ReportsLoaded>()
            .having((state) => state.selectedPeriod, 'selectedPeriod', 'All Time'),
      ],
    );
  });
}
