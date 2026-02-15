import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared/constants/app_constants.dart';
import 'core/database/database_service.dart';
import 'core/repositories/expense_group_repository.dart';
import 'core/repositories/expense_group_repository_impl.dart';
import 'core/repositories/budget_repository.dart';
import 'core/repositories/budget_repository_impl.dart';
import 'core/repositories/user_repository.dart';
import 'core/repositories/user_repository_impl.dart';
import 'core/repositories/recurring_expense_repository.dart';
import 'core/repositories/recurring_expense_repository_impl.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/auth_cubit.dart';
import 'core/router/app_router.dart';
import 'core/services/category_classifier_service.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/expenses/screens/expenses_screen.dart';
import 'features/expenses/screens/receipt_scanner_screen.dart';
import 'features/budget/screens/budget_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/dashboard/bloc/dashboard_cubit.dart';
import 'features/expenses/bloc/expense_list_cubit.dart';
import 'features/expenses/bloc/expense_filter_cubit.dart';
import 'features/budget/bloc/budget_list_cubit.dart';
import 'features/reports/bloc/reports_cubit.dart';
import 'features/budget/bloc/budget_alert_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initializeDefaultData();

  // Initialize auth
  final authService = AuthService();
  final userId = await authService.getUserId();

  // Create repositories
  final expenseGroupRepository = ExpenseGroupRepositoryImpl(databaseService);
  final budgetRepository = BudgetRepositoryImpl(databaseService);
  final userRepository = UserRepositoryImpl(databaseService);
  final recurringExpenseRepository =
      RecurringExpenseRepositoryImpl(databaseService);

  // Process due recurring expenses
  await databaseService.processDueRecurringExpenses(userId);

  // Ensure user record exists in database
  await userRepository.createUser(userId, 'User', '$userId@app.local');

  // Initialize category classifier (fire-and-forget, non-blocking)
  final classifierService = CategoryClassifierService();
  expenseGroupRepository.getExpenseGroups(userId).then((groups) {
    classifierService.initialize(groups);
  });

  runApp(FinancialPlannerApp(
    expenseGroupRepository: expenseGroupRepository,
    budgetRepository: budgetRepository,
    userRepository: userRepository,
    recurringExpenseRepository: recurringExpenseRepository,
    authService: authService,
    classifierService: classifierService,
    userId: userId,
  ));
}

class FinancialPlannerApp extends StatefulWidget {
  final ExpenseGroupRepository expenseGroupRepository;
  final BudgetRepository budgetRepository;
  final UserRepository userRepository;
  final RecurringExpenseRepository recurringExpenseRepository;
  final AuthService authService;
  final CategoryClassifierService classifierService;
  final String userId;

  const FinancialPlannerApp({
    super.key,
    required this.expenseGroupRepository,
    required this.budgetRepository,
    required this.userRepository,
    required this.recurringExpenseRepository,
    required this.authService,
    required this.classifierService,
    required this.userId,
  });

  @override
  State<FinancialPlannerApp> createState() => _FinancialPlannerAppState();
}

class _FinancialPlannerAppState extends State<FinancialPlannerApp> {
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(widget.authService)..checkAuth();
    _router = createRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ExpenseGroupRepository>.value(value: widget.expenseGroupRepository),
        RepositoryProvider<BudgetRepository>.value(value: widget.budgetRepository),
        RepositoryProvider<UserRepository>.value(value: widget.userRepository),
        RepositoryProvider<AuthService>.value(value: widget.authService),
        RepositoryProvider<RecurringExpenseRepository>.value(
            value: widget.recurringExpenseRepository),
        RepositoryProvider<CategoryClassifierService>.value(
            value: widget.classifierService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authCubit),
          BlocProvider(
            create: (context) =>
                DashboardCubit(widget.expenseGroupRepository, userId: widget.userId)
                  ..loadDashboard(),
          ),
          BlocProvider(
            create: (context) =>
                ExpenseListCubit(widget.expenseGroupRepository, userId: widget.userId)
                  ..loadExpenses(),
          ),
          BlocProvider(
            create: (context) =>
                BudgetListCubit(widget.budgetRepository, widget.expenseGroupRepository)
                  ..loadBudgets(),
          ),
          BlocProvider(
            create: (context) => ReportsCubit(
              expenseGroupRepository: widget.expenseGroupRepository,
              budgetRepository: widget.budgetRepository,
            )..loadReports(),
          ),
          BlocProvider(
            create: (context) => ExpenseFilterCubit(),
          ),
          BlocProvider(
            create: (context) =>
                BudgetAlertCubit(widget.budgetRepository, widget.expenseGroupRepository)
                  ..checkAlerts(widget.userId),
          ),
        ],
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppConstants.primaryColor,
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      textTheme: baseTextTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        primary: AppConstants.primaryColor,
        onPrimary: Colors.white,
        secondary: AppConstants.secondaryColor,
        surface: AppConstants.surfaceColor,
        error: AppConstants.errorColor,
        brightness: Brightness.light,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: AppConstants.textPrimary,
          size: 22,
        ),
        titleTextStyle: baseTextTheme.titleLarge?.copyWith(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
      ),

      // Cards — clean, borderless, subtle shadow
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          side: const BorderSide(color: AppConstants.borderColor, width: 1),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppConstants.dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppConstants.surfaceColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textTertiary,
        selectedLabelStyle: baseTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: baseTextTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        showUnselectedLabels: true,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: CircleBorder(),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        hintStyle: baseTextTheme.bodyMedium?.copyWith(
          color: AppConstants.textTertiary,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppConstants.dividerColor,
        selectedColor: AppConstants.primaryColor.withOpacity(0.12),
        labelStyle: baseTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppConstants.primaryColor,
        linearTrackColor: AppConstants.dividerColor,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ─── Main Navigation Screen ─────────────────────────────────
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = Uri.parse(GoRouterState.of(context).uri.toString());
      final tab = uri.queryParameters['tab'];
      if (tab == 'expenses') {
        setState(() => _currentIndex = 1);
      } else if (tab == 'budget') {
        setState(() => _currentIndex = 3);
      } else if (tab == 'reports') {
        setState(() => _currentIndex = 4);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppConstants.borderColor, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 0) {
              context.read<DashboardCubit>().loadDashboard();
            } else if (index == 1) {
              context.read<ExpenseListCubit>().loadExpenses();
            } else if (index == 3) {
              context.read<BudgetListCubit>().loadBudgets();
            } else if (index == 4) {
              context.read<ReportsCubit>().loadReports();
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.space_dashboard_rounded, size: 24),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.receipt_long_rounded, size: 24),
              ),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.document_scanner_rounded, size: 24),
              ),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.account_balance_wallet_rounded, size: 24),
              ),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.insights_rounded, size: 24),
              ),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
