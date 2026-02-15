import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../bloc/recurring_expense_cubit.dart';
import '../bloc/recurring_expense_state.dart';

class AddRecurringExpenseScreen extends StatefulWidget {
  const AddRecurringExpenseScreen({super.key});

  @override
  State<AddRecurringExpenseScreen> createState() =>
      _AddRecurringExpenseScreenState();
}

class _AddRecurringExpenseScreenState extends State<AddRecurringExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = AppConstants.expenseCategories.first;
  String _selectedFrequency = AppConstants.recurringFrequencies.first;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _computeNextDueDate() {
    switch (_selectedFrequency) {
      case 'daily':
        return _startDate.add(const Duration(days: 1));
      case 'weekly':
        return _startDate.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
            _startDate.year, _startDate.month + 1, _startDate.day);
      case 'yearly':
        return DateTime(
            _startDate.year + 1, _startDate.month, _startDate.day);
      default:
        return _startDate.add(const Duration(days: 30));
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _saveRecurringExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final description = _descriptionController.text;
    final nextDueDate = _computeNextDueDate();

    await context.read<RecurringExpenseCubit>().addRecurringExpense(
          amount: amount,
          category: _selectedCategory,
          description: description,
          frequency: _selectedFrequency,
          startDate: _startDate,
          endDate: _endDate,
          nextDueDate: nextDueDate,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecurringExpenseCubit, RecurringExpenseState>(
      listener: (context, state) {
        if (state is RecurringExpenseLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recurring expense added successfully!'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          context.pop();
        } else if (state is RecurringExpenseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Recurring Expense'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountField(),
                const SizedBox(height: AppSpacing.lg),
                _buildCategorySelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildDescriptionField(),
                const SizedBox(height: AppSpacing.lg),
                _buildFrequencySelector(),
                const SizedBox(height: AppSpacing.lg),
                _buildDateSelectors(),
                const SizedBox(height: AppSpacing.xl),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Amount', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
          ),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid number';
            }
            if (amount < AppConstants.minExpenseAmount) {
              return 'Amount must be at least ${AppConstants.currencySymbol}${AppConstants.minExpenseAmount}';
            }
            if (amount > AppConstants.maxExpenseAmount) {
              return 'Amount cannot exceed ${AppConstants.currencySymbol}${AppConstants.maxExpenseAmount}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          items: AppConstants.expenseCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Row(
                children: [
                  Icon(
                    AppConstants.categoryIcons[category] ?? Icons.category,
                    color: AppConstants.categoryColors[category] ?? Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(category),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCategory = value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Enter description...',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequency', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _selectedFrequency,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          items: AppConstants.recurringFrequencies.map((frequency) {
            return DropdownMenuItem<String>(
              value: frequency,
              child: Row(
                children: [
                  Icon(
                    _getFrequencyIcon(frequency),
                    color: AppConstants.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(frequency[0].toUpperCase() + frequency.substring(1)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedFrequency = value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a frequency';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dates', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Start Date',
                _startDate,
                _selectStartDate,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildOptionalDateField(
                'End Date (Optional)',
                _endDate,
                _selectEndDate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: AppTextStyles.bodyText2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalDateField(
      String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600])),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'No end date',
                    style: AppTextStyles.bodyText2.copyWith(
                      color: date != null ? null : Colors.grey[500],
                    ),
                  ),
                ),
                if (date != null)
                  GestureDetector(
                    onTap: () => setState(() => _endDate = null),
                    child: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return BlocBuilder<RecurringExpenseCubit, RecurringExpenseState>(
      builder: (context, state) {
        final isLoading = state is RecurringExpenseLoading;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _saveRecurringExpense,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Add Recurring Expense'),
          ),
        );
      },
    );
  }

  IconData _getFrequencyIcon(String frequency) {
    switch (frequency) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.view_week;
      case 'monthly':
        return Icons.calendar_month;
      case 'yearly':
        return Icons.calendar_today;
      default:
        return Icons.repeat;
    }
  }
}
