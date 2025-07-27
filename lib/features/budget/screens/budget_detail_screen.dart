import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final allExpenses = await _databaseService.database.getAllExpenses();
      final categoryExpenses = allExpenses
          .where((expense) => expense.category == widget.budget.category)
          .where((expense) =>
              expense.date.isAfter(widget.budget.periodStart) &&
              expense.date.isBefore(widget.budget.periodEnd))
          .toList();

      categoryExpenses.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _expenses = categoryExpenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expenses: $e')),
        );
      }
    }
  }

  double _getTotalSpent() {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double _getRemaining() {
    return widget.budget.limit - _getTotalSpent();
  }

  double _getPercentage() {
    return (_getTotalSpent() / widget.budget.limit).clamp(0.0, 1.0);
  }

  bool _isOverBudget() {
    return _getTotalSpent() > widget.budget.limit;
  }

  @override
  Widget build(BuildContext context) {
    final totalSpent = _getTotalSpent();
    final remaining = _getRemaining();
    final percentage = _getPercentage();
    final isOverBudget = _isOverBudget();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBudgetHeader(
                        totalSpent, remaining, percentage, isOverBudget),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBudgetProgress(percentage, isOverBudget),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPeriodInfo(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildExpensesList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBudgetHeader(double totalSpent, double remaining,
      double percentage, bool isOverBudget) {
    return Card(
      elevation: AppConstants.defaultElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppConstants.categoryColors[widget.budget.category]
                        ?.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.circular),
                  ),
                  child: Icon(
                    AppConstants.categoryIcons[widget.budget.category] ??
                        Icons.category,
                    color: AppConstants.categoryColors[widget.budget.category],
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.budget.category,
                        style: AppTextStyles.headline2,
                      ),
                      Text(
                        'Budget Period',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildHeaderItem(
                    'Budget Limit',
                    '${AppConstants.currencySymbol}${widget.budget.limit.toStringAsFixed(2)}',
                    AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildHeaderItem(
                    'Total Spent',
                    '${AppConstants.currencySymbol}${totalSpent.toStringAsFixed(2)}',
                    AppConstants.errorColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildHeaderItem(
                    isOverBudget ? 'Over Budget' : 'Remaining',
                    '${AppConstants.currencySymbol}${remaining.abs().toStringAsFixed(2)}',
                    isOverBudget
                        ? AppConstants.errorColor
                        : AppConstants.successColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBudgetProgress(double percentage, bool isOverBudget) {
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
                  'Progress',
                  style: AppTextStyles.headline3,
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
                    '${(percentage * 100).toStringAsFixed(1)}%',
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
            const SizedBox(height: AppSpacing.md),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? AppConstants.errorColor
                    : AppConstants.primaryColor,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isOverBudget
                  ? 'You are ${AppConstants.currencySymbol}${_getRemaining().abs().toStringAsFixed(2)} over your budget'
                  : 'You have ${AppConstants.currencySymbol}${_getRemaining().toStringAsFixed(2)} remaining',
              style: AppTextStyles.bodyText2.copyWith(
                color:
                    isOverBudget ? AppConstants.errorColor : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInfo() {
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
            Text(
              'Budget Period',
              style: AppTextStyles.headline3,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildPeriodItem(
                    'Start Date',
                    '${widget.budget.periodStart.day}/${widget.budget.periodStart.month}/${widget.budget.periodStart.year}',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPeriodItem(
                    'End Date',
                    '${widget.budget.periodEnd.day}/${widget.budget.periodEnd.month}/${widget.budget.periodEnd.year}',
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildExpensesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Expenses',
              style: AppTextStyles.headline3,
            ),
            Text(
              '${_expenses.length} expenses',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_expenses.isEmpty)
          Card(
            elevation: AppConstants.defaultElevation,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No expenses yet',
                    style: AppTextStyles.bodyText1
                        .copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Add expenses to see them here',
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._expenses.map((expense) => _buildExpenseCard(expense)).toList(),
      ],
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color:
                AppConstants.categoryColors[expense.category]?.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.circular),
          ),
          child: Icon(
            AppConstants.categoryIcons[expense.category] ?? Icons.category,
            color: AppConstants.categoryColors[expense.category],
            size: 20,
          ),
        ),
        title: Text(
          expense.description,
          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
        trailing: Text(
          '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodyText1.copyWith(
            color: AppConstants.errorColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => context.push('/expense-detail', extra: expense),
      ),
    );
  }
}
