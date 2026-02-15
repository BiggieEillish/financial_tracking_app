import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:financial_planner_ui_demo/features/dashboard/bloc/dashboard_state.dart';
import '../../../helpers/mock_repositories.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockExpenseGroupRepository mockExpenseGroupRepository;
  late DashboardCubit cubit;

  setUp(() {
    mockExpenseGroupRepository = MockExpenseGroupRepository();
    cubit = DashboardCubit(
      mockExpenseGroupRepository,
      userId: TestData.testUserId,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('DashboardCubit', () {
    test('initial state is DashboardInitial', () {
      expect(cubit.state, equals(DashboardInitial()));
    });

    blocTest<DashboardCubit, DashboardState>(
      'emits [Loading, Loaded] with correct calculations when loadDashboard succeeds',
      build: () {
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenAnswer((_) async => TestData.sampleExpenseGroups());
        return cubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardLoading(),
        isA<DashboardLoaded>()
            .having((state) => state.totalSpent, 'totalSpent', 405.50)
            .having((state) => state.thisMonthSpent, 'thisMonthSpent', 205.50)
            .having((state) => state.recentGroups.length, 'recentGroups length', 5)
            .having((state) => state.categoryTotals['Food'], 'categoryTotals[Food]', 40.50)
            .having((state) => state.categoryTotals['Transport'], 'categoryTotals[Transport]', 45.00)
            .having((state) => state.categoryTotals['Shopping'], 'categoryTotals[Shopping]', 120.00)
            .having((state) => state.categoryTotals['Utilities'], 'categoryTotals[Utilities]', 200.00),
      ],
      verify: (_) {
        verify(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [Loading, Loaded] with empty data when no expenses',
      build: () {
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenAnswer((_) async => []);
        return cubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardLoading(),
        isA<DashboardLoaded>()
            .having((state) => state.totalSpent, 'totalSpent', 0.0)
            .having((state) => state.thisMonthSpent, 'thisMonthSpent', 0.0)
            .having((state) => state.recentGroups, 'recentGroups', isEmpty)
            .having((state) => state.categoryTotals, 'categoryTotals', isEmpty),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'emits [Loading, Error] when loadDashboard fails',
      build: () {
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenThrow(Exception('Database error'));
        return cubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardLoading(),
        isA<DashboardError>()
            .having((state) => state.message, 'message', contains('Failed to load dashboard')),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'limits recent groups to 5 items when more groups exist',
      build: () {
        final manyGroups = List.generate(
          10,
          (i) => TestData.makeExpenseGroupWithItems(
            id: 'group_$i',
            amount: 10.0 * (i + 1),
            description: 'Expense $i',
          ),
        );
        when(() => mockExpenseGroupRepository.getExpenseGroups(TestData.testUserId))
            .thenAnswer((_) async => manyGroups);
        return cubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        DashboardLoading(),
        isA<DashboardLoaded>()
            .having((state) => state.recentGroups.length, 'recentGroups length', 5)
            .having((state) => state.totalSpent, 'totalSpent', 550.0),
      ],
    );
  });
}
