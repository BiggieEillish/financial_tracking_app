import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../../../core/models/expense_group_with_items.dart';
import '../bloc/budget_list_cubit.dart';
import '../bloc/budget_list_state.dart';

class BudgetDetailScreen extends StatelessWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetListCubit, BudgetListState>(
      builder: (context, state) {
        // Collect matching items from groups for display
        final matchingItems = <_BudgetExpenseItem>[];
        if (state is BudgetListLoaded) {
          for (final group in state.expenseGroups) {
            if (group.group.date.isAfter(budget.periodStart) &&
                group.group.date.isBefore(budget.periodEnd)) {
              for (final item in group.items) {
                if (item.category == budget.category) {
                  matchingItems.add(_BudgetExpenseItem(
                    description: item.description,
                    category: item.category,
                    amount: item.amount * item.quantity,
                    date: group.group.date,
                    groupId: group.group.id,
                  ));
                }
              }
            }
          }
          matchingItems.sort((a, b) => b.date.compareTo(a.date));
        }

        final totalSpent =
            matchingItems.fold(0.0, (sum, item) => sum + item.amount);
        final remaining = budget.limit - totalSpent;
        final percentage = (totalSpent / budget.limit).clamp(0.0, 1.0);
        final isOverBudget = totalSpent > budget.limit;

        return Scaffold(
          appBar: AppBar(
            title: Text(budget.category),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    context.read<BudgetListCubit>().loadBudgets(),
              ),
            ],
          ),
          body: state is BudgetListLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () =>
                      context.read<BudgetListCubit>().loadBudgets(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBudgetHeader(
                            totalSpent, remaining, percentage, isOverBudget),
                        const SizedBox(height: AppSpacing.lg),
                        _buildBudgetProgress(
                            percentage, isOverBudget, remaining),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPeriodInfo(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildExpensesList(context, matchingItems),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: Text(
            'Are you sure you want to delete the ${budget.category} budget?\n\n'
            'Budget: ${AppConstants.currencySymbol}${budget.limit.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteBudget(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteBudget(BuildContext context) {
    context.read<BudgetListCubit>().deleteBudget(budget.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget deleted successfully!'),
        backgroundColor: AppConstants.successColor,
      ),
    );
    context.pop();
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
                    color: AppConstants.categoryColors[budget.category]
                        ?.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.circular),
                  ),
                  child: Icon(
                    AppConstants.categoryIcons[budget.category] ??
                        Icons.category,
                    color: AppConstants.categoryColors[budget.category],
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
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
                    '${AppConstants.currencySymbol}${budget.limit.toStringAsFixed(2)}',
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

  Widget _buildBudgetProgress(
      double percentage, bool isOverBudget, double remaining) {
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
                  ? 'You are ${AppConstants.currencySymbol}${remaining.abs().toStringAsFixed(2)} over your budget'
                  : 'You have ${AppConstants.currencySymbol}${remaining.toStringAsFixed(2)} remaining',
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
                    '${budget.periodStart.day}/${budget.periodStart.month}/${budget.periodStart.year}',
                    Icons.calendar_today,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPeriodItem(
                    'End Date',
                    '${budget.periodEnd.day}/${budget.periodEnd.month}/${budget.periodEnd.year}',
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

  Widget _buildExpensesList(BuildContext context, List<_BudgetExpenseItem> items) {
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
              '${items.length} expenses',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
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
          ...items
              .map((item) => _buildExpenseCard(context, item))
              .toList(),
      ],
    );
  }

  Widget _buildExpenseCard(BuildContext context, _BudgetExpenseItem item) {
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
                AppConstants.categoryColors[item.category]?.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.circular),
          ),
          child: Icon(
            AppConstants.categoryIcons[item.category] ?? Icons.category,
            color: AppConstants.categoryColors[item.category],
            size: 20,
          ),
        ),
        title: Text(
          item.description,
          style: AppTextStyles.bodyText1.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.date.day}/${item.date.month}/${item.date.year}',
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
        trailing: Text(
          '${AppConstants.currencySymbol}${item.amount.toStringAsFixed(2)}',
          style: AppTextStyles.bodyText1.copyWith(
            color: AppConstants.errorColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BudgetExpenseItem {
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final String groupId;

  const _BudgetExpenseItem({
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.groupId,
  });
}
