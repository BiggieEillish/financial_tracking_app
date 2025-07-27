import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shared/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/database/database.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/expenses/screens/expenses_screen.dart';
import 'features/expenses/screens/add_expense_screen.dart';
import 'features/expenses/screens/expense_detail_screen.dart';
import 'features/expenses/screens/edit_expense_screen.dart';
import 'features/expenses/screens/receipt_scanner_screen.dart';
import 'features/expenses/screens/receipt_items_screen.dart';
import 'features/budget/screens/budget_screen.dart';
import 'features/budget/screens/add_budget_screen.dart';
import 'features/budget/screens/budget_detail_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/reports/screens/spending_analytics_screen.dart';
import 'features/reports/screens/category_breakdown_screen.dart';
import 'features/reports/screens/budget_performance_screen.dart';
import 'core/services/ocr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initializeDefaultData();

  runApp(const FinancialPlannerApp());
}

class FinancialPlannerApp extends StatelessWidget {
  const FinancialPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        primaryColor: AppConstants.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

// Routing configuration
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) => const AddExpenseScreen(),
    ),
    GoRoute(
      path: '/expense-detail',
      builder: (context, state) {
        final expense = state.extra as Expense;
        return ExpenseDetailScreen(expense: expense);
      },
    ),
    GoRoute(
      path: '/edit-expense',
      builder: (context, state) {
        final expense = state.extra as Expense;
        return EditExpenseScreen(expense: expense);
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
        return ReceiptItemsScreen(scanResult: scanResult);
      },
    ),
    GoRoute(
      path: '/add-budget',
      builder: (context, state) => const AddBudgetScreen(),
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

// Main Navigation Screen
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ExpensesScreen(),
    const ReceiptScannerScreen(),
    const BudgetScreen(),
    const ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Check if we should switch to expenses tab based on query parameter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
      if (uri.queryParameters['tab'] == 'expenses') {
        setState(() {
          _currentIndex = 1; // Switch to expenses tab
        });
      }
    });
  }

  // Method to refresh the current screen
  void _refreshCurrentScreen() {
    setState(() {
      // This will trigger a rebuild of the current screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan Receipt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/receipt-scanner'),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
