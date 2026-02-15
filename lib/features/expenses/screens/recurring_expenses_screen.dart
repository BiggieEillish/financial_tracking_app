import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database.dart';
import '../bloc/recurring_expense_cubit.dart';
import '../bloc/recurring_expense_state.dart';

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<RecurringExpenseCubit>().loadRecurringExpenses(),
          ),
        ],
      ),
      body: BlocBuilder<RecurringExpenseCubit, RecurringExpenseState>(
        builder: (context, state) {
          if (state is RecurringExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RecurringExpenseError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.message,
                    style:
                        AppTextStyles.bodyText2.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => context
                        .read<RecurringExpenseCubit>()
                        .loadRecurringExpenses(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is RecurringExpenseLoaded) {
            if (state.recurringExpenses.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () => context
                  .read<RecurringExpenseCubit>()
                  .loadRecurringExpenses(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: state.recurringExpenses.length,
                itemBuilder: (context, index) {
                  final expense = state.recurringExpenses[index];
                  return _buildRecurringExpenseCard(context, expense);
                },
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-recurring-expense'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.repeat, size: 100, color: Colors.grey[400]),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No recurring expenses',
            style: AppTextStyles.headline3.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add recurring expenses to track regular payments',
            style: AppTextStyles.bodyText2.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringExpenseCard(
      BuildContext context, RecurringExpense expense) {
    final categoryColor =
        AppConstants.categoryColors[expense.category] ?? Colors.grey;
    final categoryIcon =
        AppConstants.categoryIcons[expense.category] ?? Icons.category;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppConstants.errorColor,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Recurring Expense'),
            content: Text(
                'Are you sure you want to delete "${expense.description}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<RecurringExpenseCubit>().deleteRecurringExpense(expense.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${expense.description}" deleted'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      },
      child: GestureDetector(
        onLongPress: () => _showOptionsMenu(context, expense),
        child: Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          elevation: AppConstants.defaultElevation,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
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
                        color: categoryColor.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppBorderRadius.circular),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.description,
                            style: AppTextStyles.bodyText1
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            expense.category,
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${AppConstants.currencySymbol}${expense.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyText1.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _buildFrequencyBadge(expense.frequency),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Next due: ${_formatDate(expense.nextDueDate)}',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Text(
                      expense.isActive ? 'Active' : 'Inactive',
                      style: AppTextStyles.caption.copyWith(
                        color: expense.isActive
                            ? AppConstants.successColor
                            : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: expense.isActive,
                        onChanged: (value) {
                          context
                              .read<RecurringExpenseCubit>()
                              .toggleActive(expense.id, value);
                        },
                        activeColor: AppConstants.successColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyBadge(String frequency) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppConstants.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
      ),
      child: Text(
        frequency[0].toUpperCase() + frequency.substring(1),
        style: AppTextStyles.caption.copyWith(
          color: AppConstants.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, RecurringExpense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(
                expense.isActive ? Icons.pause : Icons.play_arrow,
                color: expense.isActive
                    ? AppConstants.warningColor
                    : AppConstants.successColor,
              ),
              title: Text(expense.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context
                    .read<RecurringExpenseCubit>()
                    .toggleActive(expense.id, !expense.isActive);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete, color: AppConstants.errorColor),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDelete(context, expense);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RecurringExpense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Recurring Expense'),
        content:
            Text('Are you sure you want to delete "${expense.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<RecurringExpenseCubit>()
                  .deleteRecurringExpense(expense.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${expense.description}" deleted'),
                  backgroundColor: AppConstants.errorColor,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 0) return 'Overdue (${date.day}/${date.month}/${date.year})';
    if (difference < 7) return 'In $difference days';
    return '${date.day}/${date.month}/${date.year}';
  }
}
