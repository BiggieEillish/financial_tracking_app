import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';
import 'spending_analytics_screen.dart';
import 'category_breakdown_screen.dart';
import 'budget_performance_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  List<Budget> _budgets = [];
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _databaseService.getAllExpenses();
      final budgets = await _databaseService.getAllBudgets();
      setState(() {
        _expenses = expenses;
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  List<Expense> _getFilteredExpenses() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final startOfQuarter =
        DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    switch (_selectedPeriod) {
      case 'This Week':
        return _expenses.where((e) => e.date.isAfter(startOfWeek)).toList();
      case 'This Month':
        return _expenses.where((e) => e.date.isAfter(startOfMonth)).toList();
      case 'Last Month':
        final endOfLastMonth = DateTime(now.year, now.month, 1);
        return _expenses
            .where((e) =>
                e.date.isAfter(startOfLastMonth) &&
                e.date.isBefore(endOfLastMonth))
            .toList();
      case 'This Quarter':
        return _expenses.where((e) => e.date.isAfter(startOfQuarter)).toList();
      case 'This Year':
        return _expenses.where((e) => e.date.isAfter(startOfYear)).toList();
      case 'All Time':
      default:
        return _expenses;
    }
  }

  double _getTotalSpent() {
    return _getFilteredExpenses()
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _getTotalBudget() {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.limit);
  }

  Map<String, double> _getCategorySpending() {
    final filteredExpenses = _getFilteredExpenses();
    final categorySpending = <String, double>{};

    for (final expense in filteredExpenses) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0.0) + expense.amount;
    }

    return categorySpending;
  }

  String _getTopCategory() {
    final categorySpending = _getCategorySpending();
    if (categorySpending.isEmpty) return 'No expenses';

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.first.key;
  }

  double _getAverageSpending() {
    final filteredExpenses = _getFilteredExpenses();
    if (filteredExpenses.isEmpty) return 0.0;
    return _getTotalSpent() / filteredExpenses.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSummaryCards(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickInsights(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildReportCategories(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: AppTextStyles.bodyText1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius:
                    BorderRadius.circular(AppConstants.defaultBorderRadius),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedPeriod,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: _periods.map((period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Text(period),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedPeriod = value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalSpent = _getTotalSpent();
    final totalBudget = _getTotalBudget();
    final remaining = totalBudget - totalSpent;
    final averageSpending = _getAverageSpending();
    final topCategory = _getTopCategory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Spent',
                '${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(2)}',
                Icons.payments,
                AppConstants.errorColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSummaryCard(
                'Total Budget',
                '${AppConstants.currencySymbol}${totalBudget.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                AppConstants.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Remaining',
                '${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)}',
                Icons.savings,
                remaining >= 0
                    ? AppConstants.successColor
                    : AppConstants.warningColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSummaryCard(
                'Avg. per Expense',
                '${AppConstants.currencySymbol}${averageSpending.toStringAsFixed(2)}',
                Icons.trending_up,
                AppConstants.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.bodyText1.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    final totalSpent = _getTotalSpent();
    final totalBudget = _getTotalBudget();
    final topCategory = _getTopCategory();
    final categorySpending = _getCategorySpending();
    final expenseCount = _getFilteredExpenses().length;

    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: AppConstants.warningColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Quick Insights',
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInsightItem(
              'Total Expenses',
              '$expenseCount transactions',
              Icons.receipt,
            ),
            _buildInsightItem(
              'Top Category',
              topCategory,
              AppConstants.categoryIcons[topCategory] ?? Icons.category,
              color: AppConstants.categoryColors[topCategory],
            ),
            if (totalBudget > 0)
              _buildInsightItem(
                'Budget Usage',
                '${((totalSpent / totalBudget) * 100).toStringAsFixed(1)}%',
                Icons.pie_chart,
                color: totalSpent > totalBudget
                    ? AppConstants.errorColor
                    : AppConstants.successColor,
              ),
            if (categorySpending.length > 1)
              _buildInsightItem(
                'Categories Used',
                '${categorySpending.length} categories',
                Icons.category,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyText2.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Reports',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildReportCard(
          'Spending Analytics',
          'View spending trends and patterns over time',
          Icons.trending_up,
          AppConstants.primaryColor,
          () => context.push('/spending-analytics'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildReportCard(
          'Category Breakdown',
          'See how much you spend in each category',
          Icons.pie_chart,
          AppConstants.secondaryColor,
          () => context.push('/category-breakdown'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildReportCard(
          'Budget Performance',
          'Compare your spending against your budgets',
          Icons.assessment,
          AppConstants.accentColor,
          () => context.push('/budget-performance'),
        ),
      ],
    );
  }

  Widget _buildReportCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.circular),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyText1.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
