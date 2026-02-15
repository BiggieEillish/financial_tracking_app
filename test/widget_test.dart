// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:financial_planner_ui_demo/main.dart';
import 'package:financial_planner_ui_demo/core/database/database_service.dart';
import 'package:financial_planner_ui_demo/core/repositories/expense_group_repository_impl.dart';
import 'package:financial_planner_ui_demo/core/repositories/budget_repository_impl.dart';
import 'package:financial_planner_ui_demo/core/repositories/user_repository_impl.dart';
import 'package:financial_planner_ui_demo/core/repositories/recurring_expense_repository_impl.dart';
import 'package:financial_planner_ui_demo/core/auth/auth_service.dart';
import 'package:financial_planner_ui_demo/core/services/category_classifier_service.dart';

void main() {
  testWidgets('Financial Planner App smoke test', (WidgetTester tester) async {
    final databaseService = DatabaseService();
    final expenseGroupRepository = ExpenseGroupRepositoryImpl(databaseService);
    final budgetRepository = BudgetRepositoryImpl(databaseService);
    final userRepository = UserRepositoryImpl(databaseService);
    final recurringExpenseRepository =
        RecurringExpenseRepositoryImpl(databaseService);
    final authService = AuthService();

    final classifierService = CategoryClassifierService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(FinancialPlannerApp(
      expenseGroupRepository: expenseGroupRepository,
      budgetRepository: budgetRepository,
      userRepository: userRepository,
      recurringExpenseRepository: recurringExpenseRepository,
      authService: authService,
      classifierService: classifierService,
      userId: 'test_user',
    ));

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
