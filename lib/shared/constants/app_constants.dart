import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Malaysian Financial Planner';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Automated Financial Planner with OCR and ML for Malaysian Users';

  // ─── Color Palette ───────────────────────────────────────────
  // Primary: Teal — trustworthy, fresh, distinctive
  static const Color primaryColor = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF5EEAD4);
  static const Color primaryDark = Color(0xFF0F766E);

  // Secondary & Accent
  static const Color secondaryColor = Color(0xFF6366F1);
  static const Color accentColor = Color(0xFFF59E0B);

  // Semantic
  static const Color successColor = Color(0xFF22C55E);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);

  // Surfaces
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color dividerColor = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  // Legacy aliases (used by older code)
  static const Color foodColor = Color(0xFFF97316);
  static const Color transportColor = Color(0xFF22C55E);
  static const Color shoppingColor = Color(0xFF8B5CF6);
  static const Color groceryColor = Color(0xFFF59E0B);

  // Expense Categories
  static const List<String> expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Bills & Utilities',
    'Auto & Transport',
    'Travel',
    'Fees & Charges',
    'Business Services',
    'Education',
    'Health & Medical',
    'Home',
    'Personal Care',
    'Gifts & Donations',
    'Investments',
    'Other',
  ];

  // ─── Category Colors (refined, harmonious) ──────────────────
  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFF97316),
    'Transportation': Color(0xFF22C55E),
    'Shopping': Color(0xFF8B5CF6),
    'Entertainment': Color(0xFFF59E0B),
    'Bills & Utilities': Color(0xFF6366F1),
    'Auto & Transport': Color(0xFF14B8A6),
    'Travel': Color(0xFFEC4899),
    'Fees & Charges': Color(0xFFEF4444),
    'Business Services': Color(0xFF64748B),
    'Education': Color(0xFF06B6D4),
    'Health & Medical': Color(0xFFE11D48),
    'Home': Color(0xFF78716C),
    'Personal Care': Color(0xFFA855F7),
    'Gifts & Donations': Color(0xFF3B82F6),
    'Investments': Color(0xFF16A34A),
    'Other': Color(0xFF94A3B8),
  };

  // Category Icons
  static const Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant_rounded,
    'Transportation': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Bills & Utilities': Icons.receipt_long_rounded,
    'Auto & Transport': Icons.commute_rounded,
    'Travel': Icons.flight_rounded,
    'Fees & Charges': Icons.payment_rounded,
    'Business Services': Icons.business_rounded,
    'Education': Icons.school_rounded,
    'Health & Medical': Icons.medical_services_rounded,
    'Home': Icons.home_rounded,
    'Personal Care': Icons.spa_rounded,
    'Gifts & Donations': Icons.card_giftcard_rounded,
    'Investments': Icons.trending_up_rounded,
    'Other': Icons.category_rounded,
  };

  // Currency Settings
  static const String defaultCurrency = 'MYR';
  static const String currencySymbol = 'RM';
  static const List<String> supportedCurrencies = [
    'MYR', 'USD', 'EUR', 'GBP', 'JPY',
    'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'MXN',
  ];

  // Budget Periods
  static const List<String> budgetPeriods = [
    'Weekly', 'Monthly', 'Quarterly', 'Yearly',
  ];

  // Recurring Expense Frequencies
  static const List<String> recurringFrequencies = [
    'daily', 'weekly', 'monthly', 'yearly',
  ];

  // Currency Symbols
  static const Map<String, String> currencySymbols = {
    'MYR': 'RM',
    'USD': '\$',
    'EUR': '\u20AC',
    'GBP': '\u00A3',
    'JPY': '\u00A5',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'CNY': '\u00A5',
    'INR': '\u20B9',
    'MXN': 'MX\$',
  };

  // ─── UI Settings ─────────────────────────────────────────────
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 16.0;
  static const double defaultElevation = 0.0;

  // Animation Durations
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 400;
  static const int longAnimationDuration = 800;

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 50;
  static const double minExpenseAmount = 0.01;
  static const double maxExpenseAmount = 999999.99;

  // Error Messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String unknownError =
      'An unknown error occurred. Please try again.';
  static const String authError =
      'Authentication failed. Please check your credentials.';

  // Success Messages
  static const String loginSuccess = 'Login successful!';
  static const String registerSuccess = 'Registration successful!';
  static const String expenseAddedSuccess = 'Expense added successfully!';
  static const String budgetCreatedSuccess = 'Budget created successfully!';

  // Routes
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute = '/dashboard';
  static const String addExpenseRoute = '/add-expense';
  static const String cameraRoute = '/camera';
  static const String budgetRoute = '/budget';
  static const String reportsRoute = '/reports';
}

// Responsive Breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

// ─── Typography ──────────────────────────────────────────────
class AppTextStyles {
  static const String fontFamily = 'Plus Jakarta Sans';

  static const TextStyle headline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppConstants.textPrimary,
  );

  static const TextStyle headline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppConstants.textPrimary,
  );

  static const TextStyle headline3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppConstants.textPrimary,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppConstants.textPrimary,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppConstants.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppConstants.textTertiary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.4,
    color: AppConstants.textTertiary,
  );

  static const TextStyle amountLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppConstants.textPrimary,
  );

  static const TextStyle amountMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppConstants.textPrimary,
  );
}

// ─── Spacing ─────────────────────────────────────────────────
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ─── Border Radius ───────────────────────────────────────────
class AppBorderRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 18.0;
  static const double xxl = 24.0;
  static const double circular = 50.0;
}
