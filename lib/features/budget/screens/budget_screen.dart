import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';
import 'add_budget_screen.dart';
import 'budget_detail_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final budgets = await _databaseService.getAllBudgets();
      final expenses = await _databaseService.getAllExpenses();
      setState(() {
        _budgets = budgets;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budgets: $e')),
        );
      }
    }
  }

  double _getTotalBudget() {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.limit);
  }

  double _getTotalSpent() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _getSpentForCategory(String category) {
    return _expenses
        .where((expense) => expense.category == category)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Budget? _getBudgetForCategory(String category) {
    try {
      return _budgets.firstWhere((budget) => budget.category == category);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Management'),
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
                    _buildBudgetOverview(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBudgetCategories(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBudgetOverview() {
    final totalBudget = _getTotalBudget();
    final totalSpent = _getTotalSpent();
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget) : 0.0;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Overview',
                  style: AppTextStyles.headline3,
                ),
                Icon(
                  Icons.pie_chart,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Total Budget',
                    '${AppConstants.currencySymbol}${totalBudget.toStringAsFixed(2)}',
                    AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildOverviewItem(
                    'Total Spent',
                    '${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(2)}',
                    AppConstants.errorColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildOverviewItem(
                    'Remaining',
                    '${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)}',
                    remaining >= 0
                        ? AppConstants.successColor
                        : AppConstants.warningColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 0.9
                    ? AppConstants.errorColor
                    : AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}% of budget used',
              style: AppTextStyles.caption.copyWith(
                color: percentage > 0.9
                    ? AppConstants.errorColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCategories() {
    if (_budgets.isEmpty) {
      return Card(
        elevation: AppConstants.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No budgets set',
                style:
                    AppTextStyles.headline3.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Create your first budget to start tracking your spending',
                style:
                    AppTextStyles.bodyText2.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Categories',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: AppSpacing.md),
        ..._budgets.map((budget) => _buildBudgetCard(budget)).toList(),
      ],
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    final spent = _getSpentForCategory(budget.category);
    final remaining = budget.limit - spent;
    final percentage = (spent / budget.limit).clamp(0.0, 1.0);
    final isOverBudget = spent > budget.limit;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: () => _navigateToBudgetDetail(budget),
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppConstants.categoryColors[budget.category]
                          ?.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppBorderRadius.circular),
                    ),
                    child: Icon(
                      AppConstants.categoryIcons[budget.category] ??
                          Icons.category,
                      color: AppConstants.categoryColors[budget.category],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.category,
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${AppConstants.currencySymbol}${spent.toStringAsFixed(2)} / ${AppConstants.currencySymbol}${budget.limit.toStringAsFixed(2)}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? AppConstants.errorColor.withOpacity(0.1)
                          : AppConstants.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Text(
                      isOverBudget
                          ? 'Over Budget'
                          : '${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)} left',
                      style: AppTextStyles.caption.copyWith(
                        color: isOverBudget
                            ? AppConstants.errorColor
                            : AppConstants.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? AppConstants.errorColor
                      : AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}% used',
                style: AppTextStyles.caption.copyWith(
                  color:
                      isOverBudget ? AppConstants.errorColor : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Add Budget',
                Icons.add_chart,
                AppConstants.primaryColor,
                () async {
                  final result = await context.push('/add-budget');
                  if (result == true) {
                    _loadData();
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildQuickActionCard(
                'View Reports',
                Icons.analytics,
                AppConstants.secondaryColor,
                () => context.go('/reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                title,
                style: AppTextStyles.bodyText2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBudgetDetail(Budget budget) {
    context.push('/budget-detail', extra: budget);
  }
}
