import 'package:mocktail/mocktail.dart';
import 'package:financial_planner_ui_demo/core/repositories/expense_group_repository.dart';
import 'package:financial_planner_ui_demo/core/repositories/budget_repository.dart';
import 'package:financial_planner_ui_demo/core/repositories/user_repository.dart';
import 'package:financial_planner_ui_demo/core/repositories/recurring_expense_repository.dart';
import 'package:financial_planner_ui_demo/core/auth/auth_service.dart';
import 'package:financial_planner_ui_demo/core/database/database_service.dart';
import 'package:financial_planner_ui_demo/core/services/category_classifier_service.dart';

class MockExpenseGroupRepository extends Mock implements ExpenseGroupRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockRecurringExpenseRepository extends Mock
    implements RecurringExpenseRepository {}

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockCategoryClassifierService extends Mock
    implements CategoryClassifierService {}
