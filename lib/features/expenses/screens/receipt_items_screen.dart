import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/category_classifier_service.dart';
import '../../../shared/constants/app_constants.dart';
import '../bloc/expense_form_cubit.dart';
import '../bloc/expense_form_state.dart';
import '../bloc/expense_list_cubit.dart';
import '../../dashboard/bloc/dashboard_cubit.dart';
import '../widgets/manual_item_entry_dialog.dart';

class ReceiptItemsScreen extends StatefulWidget {
  final ReceiptScanResult scanResult;

  const ReceiptItemsScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<ReceiptItemsScreen> createState() => _ReceiptItemsScreenState();
}

class _ReceiptItemsScreenState extends State<ReceiptItemsScreen> {
  final List<ReceiptItem> _items = [];
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.scanResult.date ?? DateTime.now();
    _items.addAll(widget.scanResult.items);
    _autoCategorizeItems();
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

  void _autoCategorizeItems() {
    final classifier =
        context.read<CategoryClassifierService>();
    if (!classifier.isModelReady) return;

    for (int i = 0; i < _items.length; i++) {
      if (_items[i].category == null) {
        final predictions = classifier.predict(_items[i].name, topN: 1);
        if (predictions.isNotEmpty && predictions.first.confidence > 0.15) {
          _items[i] = ReceiptItem(
            name: _items[i].name,
            price: _items[i].price,
            quantity: _items[i].quantity,
            category: predictions.first.category,
          );
        }
      }
    }
  }

  Future<void> _saveAllItems() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to save')),
      );
      return;
    }

    final receiptData = _items
        .map((item) => ReceiptExpenseData(
              amount: item.price * item.quantity,
              category: item.category ?? 'Other',
              description: '${item.name} (${item.quantity}x)',
            ))
        .toList();

    await context.read<ExpenseFormCubit>().addExpensesFromReceipt(
          items: receiptData,
          date: _selectedDate,
          receiptImage: widget.scanResult.receiptImagePath,
          storeName: widget.scanResult.storeName,
        );
  }

  void _updateItemName(int index, String name) {
    _items[index] = ReceiptItem(
      name: name,
      price: _items[index].price,
      quantity: _items[index].quantity,
      category: _items[index].category,
    );
  }

  void _updateItemPrice(int index, double price) {
    setState(() {
      _items[index] = ReceiptItem(
        name: _items[index].name,
        price: price,
        quantity: _items[index].quantity,
        category: _items[index].category,
      );
    });
  }

  void _updateItemCategory(int index, String category) {
    setState(() {
      _items[index] = ReceiptItem(
        name: _items[index].name,
        price: _items[index].price,
        quantity: _items[index].quantity,
        category: category,
      );
    });
  }

  void _updateItemQuantity(int index, int quantity) {
    if (quantity > 0) {
      setState(() {
        _items[index] = ReceiptItem(
          name: _items[index].name,
          price: _items[index].price,
          quantity: quantity,
          category: _items[index].category,
        );
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _showManualItemEntry() {
    showDialog(
      context: context,
      builder: (dialogContext) => ManualItemEntryDialog(
        onAdd: (item) {
          setState(() {
            _items.add(item);
          });
        },
      ),
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
            SnackBar(
              content: Text('Successfully saved ${_items.length} items'),
              backgroundColor: AppConstants.successColor,
            ),
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
          title: const Text('Receipt Items'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/'),
          ),
          actions: [
            if (_items.isNotEmpty)
              BlocBuilder<ExpenseFormCubit, ExpenseFormState>(
                builder: (context, state) {
                  return TextButton(
                    onPressed:
                        state is ExpenseFormSubmitting ? null : _saveAllItems,
                    child: state is ExpenseFormSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save All'),
                  );
                },
              ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: _showManualItemEntry,
          tooltip: 'Add Item',
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_items.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildReceiptSummary(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 48, color: AppConstants.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No items found',
              style: AppTextStyles.headline3.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The receipt scan didn\'t detect any items',
              style: AppTextStyles.bodyText2,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSummary() {
    final isPDF =
        widget.scanResult.receiptImagePath?.toLowerCase().endsWith('.pdf') ??
            false;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(
            bottom: BorderSide(color: AppConstants.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPDF) ...[
                Icon(Icons.picture_as_pdf_rounded,
                    color: AppConstants.errorColor, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'PDF Receipt',
                  style: AppTextStyles.caption.copyWith(
                    color: AppConstants.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  widget.scanResult.storeName ?? 'Receipt',
                  style: AppTextStyles.headline3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${AppConstants.currencySymbol}${widget.scanResult.totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.bodyText1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_items.length} items',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppConstants.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 14, color: AppConstants.textTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _formatDisplayDate(_selectedDate),
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.edit_rounded,
                      size: 12, color: AppConstants.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + delete button
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item.name,
                        style: AppTextStyles.bodyText1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          hintText: 'Item name',
                        ),
                        onChanged: (value) => _updateItemName(index, value),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded,
                          color: AppConstants.errorColor, size: 20),
                      onPressed: () => _removeItem(index),
                      tooltip: 'Remove item',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(AppSpacing.xs),
                    ),
                  ],
                ),

                // Category dropdown (full width)
                _buildCategoryDropdown(index, item.category),
                const SizedBox(height: AppSpacing.sm),

                // Price + quantity + total row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item.price.toStringAsFixed(2),
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.caption,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          prefixText: '${AppConstants.currencySymbol} ',
                          prefixStyle: AppTextStyles.caption,
                        ),
                        onChanged: (value) {
                          final price = double.tryParse(value);
                          if (price != null) {
                            _updateItemPrice(index, price);
                          }
                        },
                      ),
                    ),
                    _buildQuantitySelector(index, item.quantity),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${AppConstants.currencySymbol}${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: AppTextStyles.bodyText1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryDropdown(int index, String? currentCategory) {
    return DropdownButtonFormField<String>(
      value: currentCategory ?? 'Other',
      decoration: const InputDecoration(
        labelText: 'Category',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      isExpanded: true,
      items: AppConstants.expenseCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                AppConstants.categoryIcons[category] ??
                    Icons.category_rounded,
                color: AppConstants.categoryColors[category] ??
                    AppConstants.textTertiary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  category,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          _updateItemCategory(index, value);
        }
      },
    );
  }

  Widget _buildQuantitySelector(int index, int currentQuantity) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQtyButton(
          icon: Icons.remove_rounded,
          onPressed: () => _updateItemQuantity(index, currentQuantity - 1),
        ),
        Container(
          width: 36,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppConstants.borderColor),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Text(
            currentQuantity.toString(),
            style: AppTextStyles.bodyText1.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _buildQtyButton(
          icon: Icons.add_rounded,
          onPressed: () => _updateItemQuantity(index, currentQuantity + 1),
        ),
      ],
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: AppConstants.textSecondary,
      ),
    );
  }
}
