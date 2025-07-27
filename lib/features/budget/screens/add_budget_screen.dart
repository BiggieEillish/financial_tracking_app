import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import '../../../core/database/database.dart';

class AddBudgetScreen extends StatefulWidget {
  const AddBudgetScreen({super.key});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  String _selectedCategory = AppConstants.expenseCategories.first;
  String _selectedPeriod = AppConstants.budgetPeriods.first;
  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updatePeriodEnd();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updatePeriodEnd() {
    switch (_selectedPeriod) {
      case 'Weekly':
        _periodEnd = _periodStart.add(const Duration(days: 7));
        break;
      case 'Monthly':
        _periodEnd = DateTime(
            _periodStart.year, _periodStart.month + 1, _periodStart.day);
        break;
      case 'Quarterly':
        _periodEnd = DateTime(
            _periodStart.year, _periodStart.month + 3, _periodStart.day);
        break;
      case 'Yearly':
        _periodEnd = DateTime(
            _periodStart.year + 1, _periodStart.month, _periodStart.day);
        break;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _periodStart : _periodEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _periodStart = picked;
        } else {
          _periodEnd = picked;
        }
        _updatePeriodEnd();
      });
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      final budget = BudgetsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'default_user', // TODO: Get from auth service
        category: _selectedCategory,
        limit: amount,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
      );

      await _databaseService.database.insertBudget(budget);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budget created successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating budget: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Budget'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySelector(),
              const SizedBox(height: AppSpacing.lg),
              _buildAmountField(),
              const SizedBox(height: AppSpacing.lg),
              _buildPeriodSelector(),
              const SizedBox(height: AppSpacing.lg),
              _buildDateSelectors(),
              const SizedBox(height: AppSpacing.xl),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
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
            value: _selectedCategory,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
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
                      color: AppConstants.categoryColors[category],
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
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Amount',
          style: AppTextStyles.bodyText1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '${AppConstants.currencySymbol} ',
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            hintText: '0.00',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a budget amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter a valid amount';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Period',
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
            items: AppConstants.budgetPeriods.map((period) {
              return DropdownMenuItem<String>(
                value: period,
                child: Text(period),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPeriod = value;
                  _updatePeriodEnd();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Period Dates',
          style: AppTextStyles.bodyText1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                'Start Date',
                _periodStart,
                (date) => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildDateField(
                'End Date',
                _periodEnd,
                (date) => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
      String label, DateTime date, Function(DateTime) onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => onTap(date),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBudget,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Create Budget'),
      ),
    );
  }
}
