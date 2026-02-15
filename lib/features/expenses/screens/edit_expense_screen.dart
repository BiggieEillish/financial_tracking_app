import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/models/expense_group_with_items.dart';
import '../bloc/expense_form_cubit.dart';
import '../bloc/expense_form_state.dart';
import '../bloc/expense_list_cubit.dart';
import '../bloc/category_suggestion_cubit.dart';
import '../bloc/category_suggestion_state.dart';
import '../../dashboard/bloc/dashboard_cubit.dart';
import '../widgets/category_suggestion_chips.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseGroupWithItems expenseGroup;

  const EditExpenseScreen({
    super.key,
    required this.expenseGroup,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<_ItemEditData> _itemEdits;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.expenseGroup.group.date;
    _itemEdits = widget.expenseGroup.items.map((item) {
      return _ItemEditData(
        itemId: item.id,
        amountController: TextEditingController(text: item.amount.toString()),
        descriptionController: TextEditingController(text: item.description),
        selectedCategory: item.category,
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final edit in _itemEdits) {
      edit.amountController.dispose();
      edit.descriptionController.dispose();
    }
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

  String _formatDisplayDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Today';
    if (selected == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    for (final edit in _itemEdits) {
      if (edit.selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a category for all items')),
        );
        return;
      }
    }

    final itemUpdates = _itemEdits
        .map((edit) => ExpenseItemUpdate(
              itemId: edit.itemId,
              amount: double.parse(edit.amountController.text),
              category: edit.selectedCategory!,
              description: edit.descriptionController.text,
            ))
        .toList();

    await context.read<ExpenseFormCubit>().updateExpenseGroupWithItems(
          groupId: widget.expenseGroup.group.id,
          date: _selectedDate,
          itemUpdates: itemUpdates,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseFormCubit, ExpenseFormState>(
      listener: (context, state) {
        if (state is ExpenseFormSuccess) {
          context.read<ExpenseListCubit>().loadExpenses();
          context.read<DashboardCubit>().loadDashboard();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense updated successfully!')),
          );
          context.go('/?tab=expenses');
        } else if (state is ExpenseFormError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Expense'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date section
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

                // Items
                ...List.generate(_itemEdits.length, (index) {
                  return _buildItemSection(index);
                }),

                // Save button
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<ExpenseFormCubit, ExpenseFormState>(
                  builder: (context, state) {
                    final isSubmitting = state is ExpenseFormSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : _saveChanges,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Save Changes'),
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

  Widget _buildItemSection(int index) {
    final edit = _itemEdits[index];
    final isMultiItem = _itemEdits.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMultiItem) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Text(
              'Item ${index + 1}',
              style: AppTextStyles.caption.copyWith(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text('Amount', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: edit.amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${AppConstants.currencySymbol} ',
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
        Text('Description', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: edit.descriptionController,
          decoration: const InputDecoration(
            hintText: 'Enter description...',
          ),
          maxLines: 2,
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
        if (_itemEdits.length == 1)
          BlocBuilder<CategorySuggestionCubit, CategorySuggestionState>(
            builder: (context, state) {
              return CategorySuggestionChips(
                suggestions: state.suggestions,
                onCategorySelected: (category) {
                  setState(() {
                    edit.selectedCategory = category;
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
          hint: Text('Select Category', style: AppTextStyles.bodyText2),
          value: edit.selectedCategory,
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
              edit.selectedCategory = value;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (isMultiItem && index < _itemEdits.length - 1)
          Divider(color: AppConstants.borderColor, height: AppSpacing.lg),
      ],
    );
  }
}

class _ItemEditData {
  final String itemId;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  String? selectedCategory;

  _ItemEditData({
    required this.itemId,
    required this.amountController,
    required this.descriptionController,
    required this.selectedCategory,
  });
}
