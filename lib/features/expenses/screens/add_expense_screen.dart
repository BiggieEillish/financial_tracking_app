import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../bloc/expense_form_cubit.dart';
import '../bloc/expense_form_state.dart';
import '../bloc/expense_list_cubit.dart';
import '../bloc/category_suggestion_cubit.dart';
import '../bloc/category_suggestion_state.dart';
import '../../dashboard/bloc/dashboard_cubit.dart';
import '../../../shared/widgets/currency_selector.dart';
import '../../../core/services/currency_service.dart';
import '../widgets/category_suggestion_chips.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  String _selectedCurrency = AppConstants.defaultCurrency;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(2015);
    final initial = _selectedDate.isBefore(firstDate)
        ? firstDate
        : (_selectedDate.isAfter(now) ? now : _selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final amount = double.parse(_amountController.text);
      final category = _selectedCategory!;
      final description = _descriptionController.text;

      await context.read<ExpenseFormCubit>().addExpense(
            amount: amount,
            category: category,
            description: description,
            date: _selectedDate,
          );
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
    }
  }

  String _formatDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseFormCubit, ExpenseFormState>(
      listener: (context, state) {
        if (state is ExpenseFormSuccess) {
          context.read<ExpenseListCubit>().loadExpenses();
          context.read<DashboardCubit>().loadDashboard();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense added successfully!')),
          );
          context.go('/');
        } else if (state is ExpenseFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Expense'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount', style: AppTextStyles.headline3),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText:
                        '${CurrencyService().getSymbol(_selectedCurrency)} ',
                  ),
                  style: AppTextStyles.amountLarge.copyWith(fontSize: 24),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Date', style: AppTextStyles.headline3),
                const SizedBox(height: AppSpacing.sm),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      border: Border.all(color: AppConstants.borderColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 20, color: AppConstants.textTertiary),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          _formatDisplayDate(_selectedDate),
                          style: AppTextStyles.bodyText1,
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppConstants.textTertiary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Currency', style: AppTextStyles.headline3),
                const SizedBox(height: AppSpacing.sm),
                CurrencySelector(
                  selectedCurrency: _selectedCurrency,
                  onChanged: (currency) {
                    setState(() {
                      _selectedCurrency = currency;
                    });
                  },
                ),
                if (_selectedCurrency != AppConstants.defaultCurrency &&
                    _amountController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      'Approx. ${CurrencyService().formatAmount(CurrencyService().convert(double.tryParse(_amountController.text) ?? 0, _selectedCurrency, AppConstants.defaultCurrency), AppConstants.defaultCurrency)}',
                      style: AppTextStyles.caption,
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text('Description', style: AppTextStyles.headline3),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Enter description...',
                  ),
                  maxLines: 3,
                  onChanged: (text) {
                    context
                        .read<CategorySuggestionCubit>()
                        .onDescriptionChanged(text);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                BlocBuilder<CategorySuggestionCubit,
                    CategorySuggestionState>(
                  builder: (context, state) {
                    return CategorySuggestionChips(
                      suggestions: state.suggestions,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Category', style: AppTextStyles.headline3),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(),
                  hint: Text('Select Category',
                      style: AppTextStyles.bodyText2),
                  value: _selectedCategory,
                  items: AppConstants.expenseCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            AppConstants.categoryIcons[category] ??
                                Icons.category_rounded,
                            color: AppConstants.categoryColors[category] ??
                                AppConstants.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                BlocBuilder<ExpenseFormCubit, ExpenseFormState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            state is ExpenseFormSubmitting ? null : _saveExpense,
                        child: state is ExpenseFormSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Add Expense'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
