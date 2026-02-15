import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/features/expenses/screens/expenses_screen.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_list_state.dart';
import 'package:financial_planner_ui_demo/features/expenses/bloc/expense_filter_state.dart';
import 'package:financial_planner_ui_demo/core/models/expense_group_with_items.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockExpenseListCubit mockExpenseListCubit;
  late MockExpenseFilterCubit mockExpenseFilterCubit;

  setUp(() {
    mockExpenseListCubit = MockExpenseListCubit();
    mockExpenseFilterCubit = MockExpenseFilterCubit();
  });

  group('ExpensesScreen', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockExpenseListCubit.state)
          .thenReturn(ExpenseListLoading());
      when(() => mockExpenseFilterCubit.state)
          .thenReturn(const ExpenseFilterState());
      when(() => mockExpenseFilterCubit.filterGroups(any()))
          .thenReturn([]);

      await tester.pumpWidget(
        buildTestApp(
          child: const ExpensesScreen(),
          expenseListCubit: mockExpenseListCubit,
          expenseFilterCubit: mockExpenseFilterCubit,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error state', (tester) async {
      when(() => mockExpenseListCubit.state)
          .thenReturn(const ExpenseListError('Failed to load'));
      when(() => mockExpenseFilterCubit.state)
          .thenReturn(const ExpenseFilterState());
      when(() => mockExpenseFilterCubit.filterGroups(any()))
          .thenReturn([]);

      await tester.pumpWidget(
        buildTestApp(
          child: const ExpensesScreen(),
          expenseListCubit: mockExpenseListCubit,
          expenseFilterCubit: mockExpenseFilterCubit,
        ),
      );

      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('shows expenses list when loaded', (tester) async {
      final groups = TestData.sampleExpenseGroups();
      when(() => mockExpenseListCubit.state)
          .thenReturn(ExpenseListLoaded(groups));
      when(() => mockExpenseFilterCubit.state)
          .thenReturn(const ExpenseFilterState());
      when(() => mockExpenseFilterCubit.filterGroups(any()))
          .thenReturn(groups);

      await tester.pumpWidget(
        buildTestApp(
          child: const ExpensesScreen(),
          expenseListCubit: mockExpenseListCubit,
          expenseFilterCubit: mockExpenseFilterCubit,
        ),
      );

      expect(find.text('Expenses'), findsOneWidget);
      // displayName = storeName 'Cafe' for group g1
      expect(find.text('Cafe'), findsOneWidget);
      // displayName = first item description 'Grab ride' for group g2 (no storeName)
      expect(find.text('Grab ride'), findsOneWidget);
    });

    testWidgets('shows empty state when no expenses', (tester) async {
      when(() => mockExpenseListCubit.state)
          .thenReturn(const ExpenseListLoaded([]));
      when(() => mockExpenseFilterCubit.state)
          .thenReturn(const ExpenseFilterState());
      when(() => mockExpenseFilterCubit.filterGroups(any()))
          .thenReturn(<ExpenseGroupWithItems>[]);

      await tester.pumpWidget(
        buildTestApp(
          child: const ExpensesScreen(),
          expenseListCubit: mockExpenseListCubit,
          expenseFilterCubit: mockExpenseFilterCubit,
        ),
      );

      expect(find.text('No expenses yet'), findsOneWidget);
    });
  });
}
