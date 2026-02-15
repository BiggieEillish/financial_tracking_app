import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/models/expense_group_with_items.dart';
import '../../../core/repositories/expense_group_repository.dart';
import '../bloc/expense_list_cubit.dart';
import '../../dashboard/bloc/dashboard_cubit.dart';

class ExpenseGroupDetailScreen extends StatefulWidget {
  final ExpenseGroupWithItems expenseGroup;

  const ExpenseGroupDetailScreen({
    super.key,
    required this.expenseGroup,
  });

  @override
  State<ExpenseGroupDetailScreen> createState() =>
      _ExpenseGroupDetailScreenState();
}

class _ExpenseGroupDetailScreenState extends State<ExpenseGroupDetailScreen> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.expenseGroup.group.date;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(2015);
    final initial = _currentDate.isBefore(firstDate)
        ? firstDate
        : (_currentDate.isAfter(now) ? now : _currentDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null && picked != _currentDate) {
      await context.read<ExpenseGroupRepository>().updateExpenseGroup(
            groupId: widget.expenseGroup.group.id,
            date: picked,
          );
      setState(() {
        _currentDate = picked;
      });
      if (mounted) {
        context.read<ExpenseListCubit>().loadExpenses();
        context.read<DashboardCubit>().loadDashboard();
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    final difference = now.difference(date).inDays;
    if (difference < 7 && difference >= 0) return '$difference days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () =>
                context.push('/edit-expense', extra: widget.expenseGroup),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountCard(),
            const SizedBox(height: 24),
            if (widget.expenseGroup.group.storeName != null) ...[
              _buildStoreSection(),
              const SizedBox(height: 24),
            ],
            _buildDateSection(),
            const SizedBox(height: 24),
            _buildItemsSection(),
            const SizedBox(height: 24),
            _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor,
            AppConstants.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.currencySymbol}${widget.expenseGroup.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.expenseGroup.itemCount > 1) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.expenseGroup.itemCount} items',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Store', style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.store_rounded,
                  color: AppConstants.textTertiary, size: 20),
              const SizedBox(width: 12),
              Text(
                widget.expenseGroup.group.storeName!,
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date', style: AppTextStyles.headline3),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.borderColor),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: AppConstants.textTertiary, size: 20),
                const SizedBox(width: 12),
                Text(
                  _formatDate(_currentDate),
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit_rounded,
                    size: 16, color: AppConstants.textTertiary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.expenseGroup.isSingleItem ? 'Details' : 'Items',
          style: AppTextStyles.headline3,
        ),
        const SizedBox(height: 8),
        ...widget.expenseGroup.items.map((item) {
          final categoryColor =
              AppConstants.categoryColors[item.category] ?? Colors.grey;
          final categoryIcon =
              AppConstants.categoryIcons[item.category] ?? Icons.category;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: categoryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(categoryIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description,
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.category}${item.quantity > 1 ? ' \u2022 Qty: ${item.quantity}' : ''}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${(item.amount * item.quantity).toStringAsFixed(2)}',
                  style: AppTextStyles.bodyText1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions', style: AppTextStyles.headline3),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/edit-expense', extra: widget.expenseGroup),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete_rounded),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete this expense?\n\n'
            '${widget.expenseGroup.displayName}\n'
            '${AppConstants.currencySymbol}${widget.expenseGroup.totalAmount.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteExpenseGroup(context);
              },
              style: TextButton.styleFrom(
                  foregroundColor: AppConstants.errorColor),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpenseGroup(BuildContext context) {
    context.read<ExpenseListCubit>().deleteGroup(widget.expenseGroup.group.id);
    context.read<DashboardCubit>().loadDashboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Expense deleted successfully!'),
      ),
    );
    context.go('/?tab=expenses');
  }
}
