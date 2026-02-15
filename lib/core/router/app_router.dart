import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database.dart';
import '../../core/models/expense_group_with_items.dart';
import '../../core/repositories/expense_group_repository.dart';
import '../../core/repositories/budget_repository.dart';
import '../../core/services/ocr_service.dart';
import '../../core/auth/auth_cubit.dart';
import '../../core/auth/auth_state.dart';
import '../../features/expenses/screens/add_expense_screen.dart';
import '../../features/expenses/screens/expense_group_detail_screen.dart';
import '../../features/expenses/screens/edit_expense_screen.dart';
import '../../features/expenses/screens/receipt_scanner_screen.dart';
import '../../features/expenses/screens/receipt_items_screen.dart';
import '../../features/budget/screens/add_budget_screen.dart';
import '../../features/budget/screens/budget_detail_screen.dart';
import '../../features/reports/screens/spending_analytics_screen.dart';
import '../../features/reports/screens/category_breakdown_screen.dart';
import '../../features/reports/screens/budget_performance_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';
import '../../features/auth/screens/pin_entry_screen.dart';
import '../../features/auth/screens/settings_screen.dart';
import '../../features/expenses/bloc/expense_form_cubit.dart';
import '../../features/expenses/bloc/recurring_expense_cubit.dart';
import '../../features/expenses/bloc/category_suggestion_cubit.dart';
import '../../features/expenses/screens/recurring_expenses_screen.dart';
import '../../features/expenses/screens/add_recurring_expense_screen.dart';
import '../../core/repositories/recurring_expense_repository.dart';
import '../../core/services/category_classifier_service.dart';
import '../../features/budget/bloc/budget_form_cubit.dart';
import '../../main.dart';

/// Bridges a Stream to a [Listenable] so GoRouter re-evaluates redirects.
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createRouter(AuthCubit authCubit) {
  bool hasAuthenticated = false;

  return GoRouter(
    refreshListenable: _GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      // Once authenticated in this session, never redirect to auth again
      if (hasAuthenticated) return null;

      final authState = authCubit.state;
      final currentPath = state.uri.path;

      // Auth routes don't need redirect
      if (currentPath == '/pin-setup' || currentPath == '/pin-entry') {
        return null;
      }

      // Mark session as authenticated once we see AuthAuthenticated
      if (authState is AuthAuthenticated) {
        hasAuthenticated = true;
        return null;
      }

      // If not authenticated, redirect to appropriate auth screen
      if (authState is AuthSetupRequired) {
        return '/pin-setup';
      }
      if (authState is AuthLocked) {
        return '/pin-entry';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/pin-entry',
        builder: (context, state) => const PinEntryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) {
          final authCubit = context.read<AuthCubit>();
          final classifierService =
              context.read<CategoryClassifierService>();
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ExpenseFormCubit(
                  context.read<ExpenseGroupRepository>(),
                  userId: authCubit.userId ?? '',
                  classifierService: classifierService,
                ),
              ),
              BlocProvider(
                create: (context) =>
                    CategorySuggestionCubit(classifierService),
              ),
            ],
            child: const AddExpenseScreen(),
          );
        },
      ),
      GoRoute(
        path: '/expense-group-detail',
        builder: (context, state) {
          final expenseGroup = state.extra as ExpenseGroupWithItems;
          return ExpenseGroupDetailScreen(expenseGroup: expenseGroup);
        },
      ),
      GoRoute(
        path: '/edit-expense',
        builder: (context, state) {
          final expenseGroup = state.extra as ExpenseGroupWithItems;
          final authCubit = context.read<AuthCubit>();
          final classifierService =
              context.read<CategoryClassifierService>();
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ExpenseFormCubit(
                  context.read<ExpenseGroupRepository>(),
                  userId: authCubit.userId ?? '',
                  classifierService: classifierService,
                ),
              ),
              BlocProvider(
                create: (context) =>
                    CategorySuggestionCubit(classifierService),
              ),
            ],
            child: EditExpenseScreen(expenseGroup: expenseGroup),
          );
        },
      ),
      GoRoute(
        path: '/receipt-scanner',
        builder: (context, state) => const ReceiptScannerScreen(),
      ),
      GoRoute(
        path: '/receipt-items',
        builder: (context, state) {
          final scanResult = state.extra as ReceiptScanResult;
          final authCubit = context.read<AuthCubit>();
          final classifierService =
              context.read<CategoryClassifierService>();
          return BlocProvider(
            create: (context) => ExpenseFormCubit(
              context.read<ExpenseGroupRepository>(),
              userId: authCubit.userId ?? '',
              classifierService: classifierService,
            ),
            child: ReceiptItemsScreen(scanResult: scanResult),
          );
        },
      ),
      GoRoute(
        path: '/recurring-expenses',
        builder: (context, state) {
          final authCubit = context.read<AuthCubit>();
          return BlocProvider(
            create: (context) => RecurringExpenseCubit(
              context.read<RecurringExpenseRepository>(),
              userId: authCubit.userId ?? '',
            )..loadRecurringExpenses(),
            child: const RecurringExpensesScreen(),
          );
        },
      ),
      GoRoute(
        path: '/add-recurring-expense',
        builder: (context, state) {
          final authCubit = context.read<AuthCubit>();
          return BlocProvider(
            create: (context) => RecurringExpenseCubit(
              context.read<RecurringExpenseRepository>(),
              userId: authCubit.userId ?? '',
            ),
            child: const AddRecurringExpenseScreen(),
          );
        },
      ),
      GoRoute(
        path: '/add-budget',
        builder: (context, state) {
          final authCubit = context.read<AuthCubit>();
          return BlocProvider(
            create: (context) => BudgetFormCubit(
              context.read<BudgetRepository>(),
              userId: authCubit.userId ?? '',
            ),
            child: const AddBudgetScreen(),
          );
        },
      ),
      GoRoute(
        path: '/budget-detail',
        builder: (context, state) {
          final budget = state.extra as Budget;
          return BudgetDetailScreen(budget: budget);
        },
      ),
      GoRoute(
        path: '/spending-analytics',
        builder: (context, state) => const SpendingAnalyticsScreen(),
      ),
      GoRoute(
        path: '/category-breakdown',
        builder: (context, state) => const CategoryBreakdownScreen(),
      ),
      GoRoute(
        path: '/budget-performance',
        builder: (context, state) => const BudgetPerformanceScreen(),
      ),
    ],
  );
}
