import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Malaysian Financial Planner';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Automated Financial Planner with OCR and ML for Malaysian Users';

  // Colors
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color secondaryColor = Color(0xFF039BE5);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color foodColor = Color(0xFFE57373);
  static const Color transportColor = Color(0xFF81C784);
  static const Color shoppingColor = Color(0xFF64B5F6);
  static const Color groceryColor = Color(0xFFFFB74D);

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

  // Category Colors
  static const Map<String, Color> categoryColors = {
    'Food & Dining': Color(0xFFE57373),
    'Transportation': Color(0xFF81C784),
    'Shopping': Color(0xFF64B5F6),
    'Entertainment': Color(0xFFFFB74D),
    'Bills & Utilities': Color(0xFF9575CD),
    'Auto & Transport': Color(0xFF4DB6AC),
    'Travel': Color(0xFFF06292),
    'Fees & Charges': Color(0xFFFF8A65),
    'Business Services': Color(0xFF90A4AE),
    'Education': Color(0xFFA1C181),
    'Health & Medical': Color(0xFFEF5350),
    'Home': Color(0xFF8D6E63),
    'Personal Care': Color(0xFFBA68C8),
    'Gifts & Donations': Color(0xFF7986CB),
    'Investments': Color(0xFF66BB6A),
    'Other': Color(0xFFBDBDBD),
  };

  // Category Icons
  static const Map<String, IconData> categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_cart,
    'Entertainment': Icons.movie,
    'Bills & Utilities': Icons.receipt,
    'Auto & Transport': Icons.commute,
    'Travel': Icons.flight,
    'Fees & Charges': Icons.payment,
    'Business Services': Icons.business,
    'Education': Icons.school,
    'Health & Medical': Icons.medical_services,
    'Home': Icons.home,
    'Personal Care': Icons.spa,
    'Gifts & Donations': Icons.card_giftcard,
    'Investments': Icons.trending_up,
    'Other': Icons.category,
  };

  // Currency Settings
  static const String defaultCurrency = 'MYR';
  static const String currencySymbol = 'RM';
  static const List<String> supportedCurrencies = [
    'MYR',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'MXN'
  ];

  // Budget Periods
  static const List<String> budgetPeriods = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  // UI Settings
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 4.0;

  // Animation Durations
  static const int shortAnimationDuration = 300;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 1000;

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

// Text Styles
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}

// Spacing
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border Radius
class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double circular = 50.0;
}
