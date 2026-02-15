import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/dashboard/bloc/dashboard_cubit.dart';
import 'package:financial_planner_ui_demo/features/dashboard/bloc/dashboard_state.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_list_cubit.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_list_state.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_filter_cubit.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_filter_state.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_list_cubit.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_list_state.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_alert_cubit.dart';
import 'package:financial_planner_ui_demo/features/budget/bloc/budget_alert_state.dart';
import 'package:financial_planner_ui_demo/features/reports/bloc/reports_cubit.dart';
import 'package:financial_planner_ui_demo/features/reports/bloc/reports_state.dart';

class MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

class MockExpenseListCubit extends MockCubit<ExpenseListState>
    implements ExpenseListCubit {}

class MockExpenseFilterCubit extends MockCubit<ExpenseFilterState>
    implements ExpenseFilterCubit {}

class MockBudgetListCubit extends MockCubit<BudgetListState>
    implements BudgetListCubit {}

class MockBudgetAlertCubit extends MockCubit<BudgetAlertState>
    implements BudgetAlertCubit {}

class MockReportsCubit extends MockCubit<ReportsState>
    implements ReportsCubit {}

/// Wraps the given [child] widget with all necessary BlocProviders
/// using mock cubits for testing.
Widget buildTestApp({
  required Widget child,
  DashboardCubit? dashboardCubit,
  ExpenseListCubit? expenseListCubit,
  ExpenseFilterCubit? expenseFilterCubit,
  BudgetListCubit? budgetListCubit,
  BudgetAlertCubit? budgetAlertCubit,
  ReportsCubit? reportsCubit,
}) {
  final mockDashboard = dashboardCubit ?? MockDashboardCubit();
  final mockExpenseList = expenseListCubit ?? MockExpenseListCubit();
  final mockExpenseFilter = expenseFilterCubit ?? MockExpenseFilterCubit();
  final mockBudgetList = budgetListCubit ?? MockBudgetListCubit();
  final mockBudgetAlert = budgetAlertCubit ?? MockBudgetAlertCubit();
  final mockReports = reportsCubit ?? MockReportsCubit();

  // Set default states for any cubits not explicitly provided
  if (dashboardCubit == null) {
    when(() => mockDashboard.state).thenReturn(DashboardInitial());
  }
  if (expenseListCubit == null) {
    when(() => mockExpenseList.state).thenReturn(ExpenseListInitial());
  }
  if (expenseFilterCubit == null) {
    when(() => mockExpenseFilter.state)
        .thenReturn(const ExpenseFilterState());
  }
  if (budgetListCubit == null) {
    when(() => mockBudgetList.state).thenReturn(BudgetListInitial());
  }
  if (budgetAlertCubit == null) {
    when(() => mockBudgetAlert.state).thenReturn(BudgetAlertInitial());
  }
  if (reportsCubit == null) {
    when(() => mockReports.state).thenReturn(const ReportsInitial());
  }

  return MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<DashboardCubit>.value(value: mockDashboard),
        BlocProvider<ExpenseListCubit>.value(value: mockExpenseList),
        BlocProvider<ExpenseFilterCubit>.value(value: mockExpenseFilter),
        BlocProvider<BudgetListCubit>.value(value: mockBudgetList),
        BlocProvider<BudgetAlertCubit>.value(value: mockBudgetAlert),
        BlocProvider<ReportsCubit>.value(value: mockReports),
      ],
      child: child,
    ),
  );
}
