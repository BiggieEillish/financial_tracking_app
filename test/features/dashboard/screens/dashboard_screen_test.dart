import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/dashboard/screens/dashboard_screen.dart';
import 'package:financial_planner_ui_demo/features/dashboard/bloc/dashboard_state.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_alert_state.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockDashboardCubit mockDashboardCubit;
  late MockBudgetAlertCubit mockBudgetAlertCubit;

  setUp(() {
    mockDashboardCubit = MockDashboardCubit();
    mockBudgetAlertCubit = MockBudgetAlertCubit();
  });

  group('DashboardScreen', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockDashboardCubit.state).thenReturn(DashboardLoading());
      when(() => mockBudgetAlertCubit.state).thenReturn(BudgetAlertInitial());

      await tester.pumpWidget(
        buildTestApp(
          child: const DashboardScreen(),
          dashboardCubit: mockDashboardCubit,
          budgetAlertCubit: mockBudgetAlertCubit,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error state', (tester) async {
      when(() => mockDashboardCubit.state)
          .thenReturn(const DashboardError('Something went wrong'));
      when(() => mockBudgetAlertCubit.state).thenReturn(BudgetAlertInitial());

      await tester.pumpWidget(
        buildTestApp(
          child: const DashboardScreen(),
          dashboardCubit: mockDashboardCubit,
          budgetAlertCubit: mockBudgetAlertCubit,
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows dashboard content when loaded', (tester) async {
      final groups = TestData.sampleExpenseGroups();
      when(() => mockDashboardCubit.state).thenReturn(DashboardLoaded(
        recentGroups: groups.take(5).toList(),
        totalSpent: 405.50,
        thisMonthSpent: 205.50,
        categoryTotals: {
          'Food': 40.50,
          'Transport': 45.00,
          'Shopping': 120.00,
        },
      ));
      when(() => mockBudgetAlertCubit.state)
          .thenReturn(const BudgetAlertLoaded([]));

      await tester.pumpWidget(
        buildTestApp(
          child: const DashboardScreen(),
          dashboardCubit: mockDashboardCubit,
          budgetAlertCubit: mockBudgetAlertCubit,
        ),
      );

      // Time-based greeting (Good morning/afternoon/evening)
      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? 'Good morning!'
          : hour < 17
              ? 'Good afternoon!'
              : 'Good evening!';
      expect(find.text(greeting), findsOneWidget);
      expect(find.text('Total Spent'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Recent Expenses'), findsOneWidget);
    });

    testWidgets('shows empty state when no expenses', (tester) async {
      when(() => mockDashboardCubit.state).thenReturn(const DashboardLoaded(
        recentGroups: [],
        totalSpent: 0.0,
        thisMonthSpent: 0.0,
        categoryTotals: {},
      ));
      when(() => mockBudgetAlertCubit.state)
          .thenReturn(const BudgetAlertLoaded([]));

      await tester.pumpWidget(
        buildTestApp(
          child: const DashboardScreen(),
          dashboardCubit: mockDashboardCubit,
          budgetAlertCubit: mockBudgetAlertCubit,
        ),
      );

      expect(find.text('No expenses yet'), findsOneWidget);
    });

    testWidgets('shows spending by category when data available',
        (tester) async {
      when(() => mockDashboardCubit.state).thenReturn(const DashboardLoaded(
        recentGroups: [],
        totalSpent: 165.00,
        thisMonthSpent: 165.00,
        categoryTotals: {
          'Food': 40.50,
          'Transport': 45.00,
          'Shopping': 79.50,
        },
      ));
      when(() => mockBudgetAlertCubit.state)
          .thenReturn(const BudgetAlertLoaded([]));

      await tester.pumpWidget(
        buildTestApp(
          child: const DashboardScreen(),
          dashboardCubit: mockDashboardCubit,
          budgetAlertCubit: mockBudgetAlertCubit,
        ),
      );

      expect(find.text('Spending by Category'), findsOneWidget);
    });
  });
}
