import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/database/database_service.dart';
import '../../../shared/constants/app_constants.dart';

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
  final DatabaseService _databaseService = DatabaseService();
  final PDFService _pdfService = PDFService();
  final List<ReceiptItem> _items = [];
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.scanResult.items);
  }

  Future<void> _saveAllItems() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to save')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      const userId = 'default_user'; // In a real app, get from auth

      for (final item in _items) {
        await _databaseService.addExpense(
          userId: userId,
          amount: item.price * item.quantity,
          category: item.category ?? 'Other',
          description: '${item.name} (${item.quantity}x)',
          date: widget.scanResult.date ?? DateTime.now(),
          receiptImage: widget.scanResult.receiptImagePath,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully saved ${_items.length} items'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving items: $e';
        _isSaving = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Items'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveAllItems,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save All'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_items.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildReceiptSummary(),
        Expanded(
          child: _buildItemsList(),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No items found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'The receipt scan didn\'t detect any items',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptSummary() {
    final isPDF =
        widget.scanResult.receiptImagePath?.toLowerCase().endsWith('.pdf') ??
            false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPDF) ...[
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'PDF Receipt',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  widget.scanResult.storeName ?? 'Receipt',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${AppConstants.currencySymbol}${widget.scanResult.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_items.length} items',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (widget.scanResult.date != null) ...[
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDate(widget.scanResult.date!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeItem(index),
                      tooltip: 'Remove item',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCategoryDropdown(index, item.category),
                    ),
                    const SizedBox(width: 16),
                    _buildQuantitySelector(index, item.quantity),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price: ${AppConstants.currencySymbol}${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Total: ${AppConstants.currencySymbol}${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
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
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: AppConstants.expenseCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                AppConstants.categoryIcons[category] ?? Icons.category,
                color: AppConstants.categoryColors[category] ?? Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(category),
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
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => _updateItemQuantity(index, currentQuantity - 1),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            currentQuantity.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _updateItemQuantity(index, currentQuantity + 1),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
